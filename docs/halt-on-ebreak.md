# Halt on `ebreak`

## Motivation

Test programs currently end with `jal x0, 0`, an infinite self-loop, and
`run_program` runs for a fixed `cycles` count. That has two problems:

- The core keeps fetching and executing after the program is logically done,
  so results can depend on the selected cycle budget.
- The top model has no way to know that the program finished. The test harness
  cannot distinguish "program completed" from "not enough cycles".

This note proposes a `halt` output on `core_top`, driven by the RISC-V
`ebreak` instruction. Programs then end with a single `ebreak` and the harness
waits for `halt` instead of guessing a cycle count.

## RISC-V compatibility

`ebreak` (`0x00100073`) is a standard RISC-V instruction. In a full machine it
raises a breakpoint exception and traps through `mtvec`. This core has no CSR
file or trap support, so we define `ebreak` as "end of program" for simulation
purposes. No encoding changes, custom instructions, or assembler patches are
required; the stock toolchain already assembles `ebreak`.

If CSRs and traps are added later, the semantics can be revisited (breakpoint
exception, or a semihosting/`tohost` convention) without changing the harness
contract much.

## Proposed design

Detect `ebreak` in decode and turn it into a bubble, let all older
instructions retire, then raise a sticky `halt` once the bubble reaches the
write-back stage.

Pipeline order is `F -> D -> A -> M -> WB`. When `ebreak` is decoded, the
instructions in A/M/WB are *older* and must complete; the instruction in F is
*younger* and must be squashed. Importantly, `run` must **not** be dropped at
decode: both `rf_wen` and `dmem_wen` are gated with `run`
(`wb_stage.sv:21`, `m_stage.sv:32`), so pulling it low early would drop an
older instruction's write-back or store.

### Control flow

1. **Decode**: `is_ebreak` is asserted when the decoded instruction is
   `0x00100073`.
2. **Squash and freeze**: while `flush` is active
   - force the D->A control bundle to a NOP
     (`writes_rd = is_load = is_store = pc_wen = 0`),
   - hold the program counter,
   - inject a NOP into the fetch stage instead of `imem_rdata`.
3. **Sticky drain**: `flush = is_ebreak | halt_pending`, with
   `halt_pending` set when `ebreak` is decoded and cleared only by reset.
   A one-cycle flush is not enough because `f_stage.sv:38` unconditionally
   latches `imem_rdata`; with a frozen PC that would refetch the same younger
   instruction every cycle.
4. **Carry the flag down**: register `is_ebreak` through A -> M -> WB alongside
   the bubble.
5. **Halt**: when the flag reaches WB, assert `halt`. At that point every
   older instruction has retired, so gating with `core_run = run & ~halt` is
   safe.

### Signal sketch

```systemverilog
// decoder.sv
localparam logic [31:0] INSTR_EBREAK = 32'h00100073;

output logic is_ebreak;
assign is_ebreak = (ir == INSTR_EBREAK);
```

```systemverilog
// core_top.sv
output logic halt;

logic halt_pending;
logic d_is_ebreak;      // from the decoder
logic a_is_ebreak, m_is_ebreak;
logic flush;
logic core_run;

assign flush    = d_is_ebreak | halt_pending;
assign core_run = run & ~halt;

always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        halt_pending <= 0;
        a_is_ebreak  <= 0;
        m_is_ebreak  <= 0;
        halt         <= 0;
    end else begin
        if (d_is_ebreak)
            halt_pending <= 1;
        a_is_ebreak <= d_is_ebreak;
        m_is_ebreak <= a_is_ebreak;
        halt        <= m_is_ebreak;
    end
end
```

`fetch` gains a `flush` input:

```systemverilog
// f_stage.sv
input logic flush;

pc pc_mod(
    .clk(clk),
    .rst(rst),
    .run(run & ~flush),   // hold PC while draining
    .w_en(wen_pc),
    .addr_in(waddr_pc),
    .out(next_pc)
);

always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        f_ir <= 0;
        f_pc <= 0;
    end else begin
        f_ir <= flush ? 32'h00000013 : imem_rdata;  // 32'h00000013 = nop
        f_pc <= next_pc;
    end
end
```

The D->A control bundle must also be muxed to NOP when `d_is_ebreak` is
asserted. Because `d_pc_wen` is a registered signal, the PC hold during the
detection cycle is best done through `pc.run = run & ~flush` rather than
relying on `d_pc_wen` alone.

### Timing

With `ebreak` in D at cycle 0:

| cycle | F              | D         | A     | M     | WB     | `halt` |
|-------|----------------|-----------|-------|-------|--------|--------|
| 0     | younger (kill) | `ebreak`  | older | older | older  | 0      |
| 1     | nop            | nop       | nop   | older | older  | 0      |
| 2     | nop            | nop       | nop   | nop   | older  | 0      |
| 3     | nop            | nop       | nop   | nop   | `ebreak` | 1    |

Older instructions retire on cycles 0-2; `halt` asserts on cycle 3.

## Harness changes

`run_program` should wait for `halt` with a timeout instead of relying on a
fixed `cycles` value. Existing callers keep working if a `timeout_cycles`
default is provided:

```python
dut.run.value = 1
for _ in range(timeout_cycles):
    await RisingEdge(dut.clk)
    if dut.halt.value:
        break
else:
    raise TimeoutError("program did not halt")
```

Post-conditions are then checked after `halt`, at which point all writes have
retired. Test programs drop the trailing `jal x0, 0` in favour of `ebreak`.

## Edge cases

- `ebreak` as the first instruction: no older work; `halt` after the pipeline
  drain.
- Branch/jump to `ebreak`: works the same; the fetch PC is held from decode
  onwards.
- Load/store in A/M when `ebreak` is decoded: `core_run` stays high until the
  bubble reaches WB, so these complete normally.
- Reset during drain: `rst` clears `halt_pending` and `halt`.
- Multiple `ebreak`s: the first one sets `halt_pending`; later fetches are
  squashed.

## Alternatives considered

- **`tohost` store** (riscv-tests / HTIF convention): store to a magic address
  and decode it as halt. No ISA semantics change and it carries an exit code,
  but it burns an address range and needs store-address decoding.
- **`ecall` + traps/CSRs**: the architecturally proper route, but requires
  `mcause`/`mepc`/`mtvec` and a trap handler, which the core does not have.
- **Valid bits instead of NOP injection**: `f_valid`/`d_valid` bits propagate
  through the stages and suppress writes. Cleaner long-term, but a larger
  change than the current pipeline needs.

## Follow-ups

- Add valid/ready bits to the pipeline; this replaces the NOP-injection hack
  and simplifies the squash.
- Optionally define an exit code (e.g. `a0` at `halt`, or a `tohost` store).
- Update all test programs and the dmem preload test to end with `ebreak`.
- Add a test for `ebreak` in the middle of a taken branch.

## Files affected

- `rtl/decoder.sv` - detect `0x00100073`.
- `rtl/d_stage.sv` - expose `is_ebreak`, mux D->A controls to NOP.
- `rtl/f_stage.sv` - `flush` input, NOP injection, PC hold.
- `rtl/a_stage.sv`, `rtl/m_stage.sv`, `rtl/wb_stage.sv` - carry the flag.
- `rtl/core_top.sv` - `halt` output, `halt_pending`, `core_run`.
- `rtl_tests/test_programs/harness.py` - wait on `halt`, timeout.
- `rtl_tests/test_core_top.py`, `rtl_tests/test_programs/*.S` - end with
  `ebreak`.
