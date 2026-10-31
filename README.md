## MIRI PA Project

This repository contains a work-in-progress RV32I compliant core, developed for the [`Processor Architecture`](https://www.fib.upc.edu/en/masters/master-innovation-and-research-informatics/curriculum/syllabus/PA-MIRI) class, taught at _Universitat Politècnica de Catalunya_.

## Setup

After cloning the repository, initialize and fetch git submodules (required for the `riscv-assembler` dependency in `vendor/riscv-assembler`):

```bash
git submodule update --init --recursive
```

Alternatively, clone with submodules in one step:

```bash
git clone --recurse-submodules <repository-url>
```

## Testing

```
cd rtl_tests && uv run make
```

## General TODOs

- [ ] Add linter and formatter, with standardized rules. This will help when the project starts growing.
- [ ] Add CI with linter, formattes, and tests.

## AI Usage Disclosure

AI tools were used as assitance to build **ONLY** testing and utility code (`rlt_tests/`) (cocotb wrappers, loader code, etc.). The main core RTL codebase (`rtl/`) was developed by humans, as requested. Beware of the lack of beauty (right now, will improve over time ;)), when reading the codebase.

