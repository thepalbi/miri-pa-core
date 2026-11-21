"""Post-condition assertions embedded in assembly comments.

An assertion is a comment whose text starts with ``!``, for example::

    # !rf[1] == 0
    // !rf[2] == 20

Only register-file checks are supported for now. The right-hand side may be a
decimal or hexadecimal integer.
"""

from dataclasses import dataclass
import re

_ASSERTION_RE = re.compile(
    r"!\s*(?P<target>[A-Za-z_]\w*)\s*\[\s*(?P<index>\d+)\s*\]"
    r"\s*==\s*(?P<expected>[+-]?(?:0[xX][0-9a-fA-F]+|\d+))"
)


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


def _parse_comment(comment: str, line: int) -> Assertion | None:
    text = comment.strip()
    if not text.startswith("!"):
        return None

    match = _ASSERTION_RE.fullmatch(text)
    if match is None:
        raise ValueError(
            f"Malformed assertion on line {line}: expected "
            f"'!rf[<index>] == <integer>', got {text!r}"
        )

    target = match.group("target")
    if target != "rf":
        raise ValueError(
            f"Unsupported assertion target {target!r} on line {line} "
            "(only 'rf' is supported)"
        )

    return Assertion(
        target=target,
        index=int(match.group("index")),
        expected=int(match.group("expected"), 0),
        line=line,
    )


def extract_assertions(source: str) -> tuple[str, list[Assertion]]:
    """Extract assertions from ``source`` and return source with them removed."""
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
        assertion = _parse_comment(comment_text, line_number)
        if assertion is None:
            cleaned_lines.append(line)
            continue

        assertions.append(assertion)
        cleaned_lines.append(body[:comment_start].rstrip() + newline)

    return "".join(cleaned_lines), assertions


def check_assertions(dut, assertions: list[Assertion]) -> None:
    """Evaluate assertions against the register file after a program has run."""
    failures: list[str] = []

    for assertion in assertions:
        actual = int(getattr(dut, assertion.target).regs[assertion.index].value)
        if actual != assertion.expected:
            failures.append(
                f"line {assertion.line}: {assertion.target}[{assertion.index}] "
                f"expected {assertion.expected}, got {actual}"
            )

    assert not failures, "Post-condition assertion(s) failed:\n" + "\n".join(failures)
