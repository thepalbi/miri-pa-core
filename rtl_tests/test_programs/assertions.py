"""Pre- and post-conditions embedded in assembly comments.

A comment whose text starts with ``!`` is a *pre-condition*: it is evaluated
before the program runs, and currently only data-memory pre-loading is
supported::

    # !dmem[0x100] = 0xdeadbeef
    // !dmem[16] = 42

A comment whose text starts with ``?`` is a *post-condition* (an assertion
checked after the program runs), for example::

    # ?rf[1] == 0
    // ?rf[2] == 20
    # ?dmem[0x100] == 0xdeadbeef

Integers may be decimal or hexadecimal. ``rf[i]`` refers to register-file
index ``i``; ``dmem[a]`` refers to data-memory word address ``a``.
"""

from dataclasses import dataclass
import re

_INTEGER = r"[+-]?(?:0[xX][0-9a-fA-F]+|\d+)"

_PRE_RE = re.compile(
    r"!\s*(?P<target>[A-Za-z_]\w*)\s*\[\s*(?P<index>" + _INTEGER + r")\s*\]"
    r"\s*=\s*(?P<value>" + _INTEGER + r")"
)

_POST_RE = re.compile(
    r"\?\s*(?P<target>[A-Za-z_]\w*)\s*\[\s*(?P<index>" + _INTEGER + r")\s*\]"
    r"\s*==\s*(?P<expected>" + _INTEGER + r")"
)


@dataclass(frozen=True)
class Precondition:
    target: str
    index: int
    value: int
    line: int


@dataclass(frozen=True)
class Assertion:
    target: str
    index: int
    expected: int
    line: int


def _find_comment(line: str) -> tuple[int, str] | None:
    """Return the start and text of the first ``#`` or ``//`` comment."""
    hash_index = line.find("#")
    slash_index = line.find("//")

    indexes = [index for index in (hash_index, slash_index) if index != -1]
    if not indexes:
        return None

    start = min(indexes)
    marker_len = 2 if line.startswith("//", start) else 1
    return start, line[start + marker_len :]


def _parse_comment(
    comment: str, line: int
) -> Precondition | Assertion | None:
    text = comment.strip()

    if text.startswith("!"):
        match = _PRE_RE.fullmatch(text)
        if match is None:
            raise ValueError(
                f"Malformed pre-condition on line {line}: expected "
                f"'!dmem[<address>] = <integer>', got {text!r}"
            )

        target = match.group("target")
        if target != "dmem":
            raise ValueError(
                f"Unsupported pre-condition target {target!r} on line {line} "
                "(only 'dmem' is supported)"
            )

        return Precondition(
            target=target,
            index=int(match.group("index"), 0),
            value=int(match.group("value"), 0),
            line=line,
        )

    if text.startswith("?"):
        match = _POST_RE.fullmatch(text)
        if match is None:
            raise ValueError(
                f"Malformed post-condition on line {line}: expected "
                f"'?rf[<index>] == <integer>' or '?dmem[<address>] == "
                f"<integer>', got {text!r}"
            )

        target = match.group("target")
        if target not in ("rf", "dmem"):
            raise ValueError(
                f"Unsupported post-condition target {target!r} on line {line} "
                "(only 'rf' and 'dmem' are supported)"
            )

        return Assertion(
            target=target,
            index=int(match.group("index"), 0),
            expected=int(match.group("expected"), 0),
            line=line,
        )

    return None


def extract_directives(
    source: str,
) -> tuple[str, list[Precondition], list[Assertion]]:
    """Extract pre- and post-conditions from ``source``, removing them."""
    preconditions: list[Precondition] = []
    assertions: list[Assertion] = []
    cleaned_lines: list[str] = []

    for line_number, line in enumerate(source.splitlines(keepends=True), start=1):
        body = line.rstrip("\r\n")
        newline = line[len(body) :]

        comment = _find_comment(body)
        if comment is None:
            cleaned_lines.append(line)
            continue

        comment_start, comment_text = comment
        directive = _parse_comment(comment_text, line_number)
        if directive is None:
            cleaned_lines.append(line)
            continue

        if isinstance(directive, Precondition):
            preconditions.append(directive)
        else:
            assertions.append(directive)
        cleaned_lines.append(body[:comment_start].rstrip() + newline)

    return "".join(cleaned_lines), preconditions, assertions


def check_assertions(dut, assertions: list[Assertion]) -> None:
    """Evaluate post-conditions after a program has run."""
    failures: list[str] = []

    for assertion in assertions:
        actual = _read_memory(dut, assertion.target, assertion.index)
        if actual != assertion.expected:
            failures.append(
                f"line {assertion.line}: {assertion.target}"
                f"[{assertion.index}] expected {assertion.expected}, got {actual}"
            )

    assert not failures, "Post-condition assertion(s) failed:\n" + "\n".join(failures)


def _read_memory(dut, target: str, index: int) -> int:
    if target == "rf":
        return int(dut.rf.regs[index].value)
    return int(dut.dmem.bank[index].value)
