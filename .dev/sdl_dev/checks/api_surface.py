"""Check that the API reference covers CangjieSDL's public surface."""

import re
from pathlib import Path

from sdl_dev.common.paths import REPOSITORY_ROOT


SOURCE_ROOT = REPOSITORY_ROOT / "src"
API_ROOT = REPOSITORY_ROOT / "docs" / "api" / "sdl"
PACKAGE = re.compile(r"(?m)^package\s+(sdl(?:\.[a-z][a-z0-9_]*)*)\s*$")
PUBLIC_TYPE = re.compile(
    r"(?m)^public\s+(?:open\s+)?(?:class|interface|struct|enum)\s+([A-Za-z_][A-Za-z0-9_]*)"
)
EXTENSION = re.compile(r"(?m)^extend\s+([A-Za-z_][A-Za-z0-9_]*)")
PUBLIC_FUNCTION = re.compile(r"(?m)^public\s+func\s+([A-Za-z_][A-Za-z0-9_]*)")
PUBLIC_MEMBER = re.compile(
    r"^public\s+(?:(?:static|mut|open|override)\s+)*(let|var|prop|func)\s+([A-Za-z_][A-Za-z0-9_]*)"
)
PUBLIC_OPERATOR = re.compile(r"^public\s+operator\s+func\s+([^\s(]+)")
INTERFACE_MEMBER = re.compile(r"^(?:(?:static|mut)\s+)*(prop|func)\s+([A-Za-z_][A-Za-z0-9_]*)")
ENUM_CASE = re.compile(r"^\|\s*([A-Za-z_][A-Za-z0-9_]*)")
CALLABLE_START = re.compile(
    r"(?m)^[ \t]*public\s+(?:(?:static|mut|open|override)\s+)*"
    r"(?:(?:operator\s+)?func\s+[A-Za-z_][A-Za-z0-9_]*|operator\s+func\s+[^\s(]+|init)\b"
)
SPECIAL_PAGES = {"functions.md", "index.md"}


def _code_only(text: str) -> str:
    """Blank comments and strings while preserving braces and line positions."""
    output: list[str] = []
    index = 0
    state = "code"
    while index < len(text):
        if state == "code":
            if text.startswith("//", index):
                output.extend("  ")
                index += 2
                state = "line-comment"
            elif text.startswith("/*", index):
                output.extend("  ")
                index += 2
                state = "block-comment"
            elif text[index] == '"':
                output.append(" ")
                index += 1
                state = "string"
            else:
                output.append(text[index])
                index += 1
        elif state == "line-comment":
            output.append("\n" if text[index] == "\n" else " ")
            if text[index] == "\n":
                state = "code"
            index += 1
        elif state == "block-comment":
            if text.startswith("*/", index):
                output.extend("  ")
                index += 2
                state = "code"
            else:
                output.append("\n" if text[index] == "\n" else " ")
                index += 1
        elif text[index] == "\\" and index + 1 < len(text):
            output.extend("  ")
            index += 2
        elif text[index] == '"':
            output.append(" ")
            index += 1
            state = "code"
        else:
            output.append("\n" if text[index] == "\n" else " ")
            index += 1
    return "".join(output)


def _package_key(package: str) -> str:
    return package[4:] if package.startswith("sdl.") else ""


def _package_docs(api_root: Path, package_key: str) -> Path:
    return api_root.joinpath(*package_key.split(".")) if package_key else api_root


def _declaration_blocks(code: str):
    declarations = []
    for match in PUBLIC_TYPE.finditer(code):
        tokens = match.group(0).split()
        kind = tokens[2] if tokens[1] == "open" else tokens[1]
        declarations.append((match.start(), match, kind, match.group(1)))
    for match in EXTENSION.finditer(code):
        declarations.append((match.start(), match, "extension", match.group(1)))
    return sorted(declarations)


def _block_end(code: str, opening: int) -> int | None:
    depth = 0
    for position in range(opening, len(code)):
        if code[position] == "{":
            depth += 1
        elif code[position] == "}":
            depth -= 1
            if depth == 0:
                return position
    return None


def _normalize_signature(signature: str) -> str:
    signature = re.sub(r"//[^\n]*", "", signature)
    signature = re.sub(r"/\*.*?\*/", "", signature, flags=re.DOTALL)
    # Formatting may wrap a signature at any token boundary. Removing whitespace
    # keeps the comparison strict for names, types, defaults, and return values.
    return re.sub(r"\s+", "", signature)


def _callable_signatures(text: str) -> dict[str, list[str]]:
    """Return normalized public callable signatures for types and extensions."""
    code = _code_only(text)
    result: dict[str, list[str]] = {}
    for _, match, _, name in _declaration_blocks(code):
        opening = code.find("{", match.end())
        if opening < 0:
            continue
        closing = _block_end(code, opening)
        if closing is None:
            continue
        segment = code[opening + 1:closing]
        for callable_match in CALLABLE_START.finditer(segment):
            relative = callable_match.start()
            if segment[:relative].count("{") != segment[:relative].count("}"):
                continue
            start = opening + 1 + callable_match.start()
            body = code.find("{", opening + 1 + callable_match.end(), closing)
            if body < 0:
                continue
            signature = _normalize_signature(text[start:body])
            result.setdefault(name, []).append(signature)
    return result


def _top_level_function_signatures(text: str) -> dict[str, list[str]]:
    code = _code_only(text)
    result: dict[str, list[str]] = {}
    for match in PUBLIC_FUNCTION.finditer(code):
        body = code.find("{", match.end())
        if body < 0:
            continue
        signature = _normalize_signature(text[match.start():body])
        result.setdefault(match.group(1), []).append(signature)
    return result


def _type_members(text: str) -> dict[str, dict[tuple[str, str], int]]:
    code = _code_only(text)
    result: dict[str, dict[tuple[str, str], int]] = {}
    for _, match, kind, name in _declaration_blocks(code):
        opening = code.find("{", match.end())
        if opening < 0:
            continue
        depth = 0
        closing = None
        for position in range(opening, len(code)):
            if code[position] == "{":
                depth += 1
            elif code[position] == "}":
                depth -= 1
                if depth == 0:
                    closing = position
                    break
        if closing is None:
            continue

        members: dict[tuple[str, str], int] = {}
        depth = 1
        for line in code[opening + 1:closing].splitlines():
            stripped = line.strip()
            if depth == 1:
                member = PUBLIC_MEMBER.match(stripped)
                if member is None and kind == "interface":
                    member = INTERFACE_MEMBER.match(stripped)
                if member is not None:
                    key = member.groups()
                    members[key] = members.get(key, 0) + 1
                else:
                    operator = PUBLIC_OPERATOR.match(stripped)
                    if operator is not None:
                        key = ("operator", operator.group(1))
                        members[key] = members.get(key, 0) + 1
                    elif re.match(r"^public\s+init\b", stripped):
                        key = ("init", "init")
                        members[key] = members.get(key, 0) + 1
                    elif kind == "enum":
                        enum_case = ENUM_CASE.match(stripped)
                        if enum_case is not None:
                            key = ("case", enum_case.group(1))
                            members[key] = members.get(key, 0) + 1
            depth += line.count("{") - line.count("}")
        target = result.setdefault(name, {})
        for member, count in members.items():
            target[member] = target.get(member, 0) + count
    return result


def source_surface(source_root: Path = SOURCE_ROOT):
    types: set[tuple[str, str]] = set()
    functions: dict[tuple[str, str], int] = {}
    members: dict[tuple[str, str], dict[tuple[str, str], int]] = {}
    packages: set[str] = set()
    for path in sorted(source_root.rglob("*.cj")):
        if path.name.endswith("_test.cj"):
            continue
        text = path.read_text(encoding="utf-8")
        package_match = PACKAGE.search(text)
        if package_match is None:
            continue
        package_key = _package_key(package_match.group(1))
        packages.add(package_key)
        for match in PUBLIC_TYPE.finditer(text):
            types.add((package_key, match.group(1)))
        for match in PUBLIC_FUNCTION.finditer(text):
            key = (package_key, match.group(1))
            functions[key] = functions.get(key, 0) + 1
        for type_name, found in _type_members(text).items():
            target = members.setdefault((package_key, type_name), {})
            for member, count in found.items():
                target[member] = target.get(member, 0) + count
    return types, functions, members, packages


def _documented_callable_count(text: str, kind: str, name: str) -> int:
    if kind == "init":
        return len(re.findall(r"\bpublic\s+init\b", text))
    if kind == "func":
        return len(re.findall(rf"\bpublic\s+(?:static\s+)?func\s+{re.escape(name)}\b", text))
    if kind == "operator":
        return len(re.findall(rf"\bpublic\s+operator\s+func\s+{re.escape(name)}", text))
    return 0


def api_surface_failures(source_root: Path = SOURCE_ROOT, api_root: Path = API_ROOT) -> list[str]:
    failures: list[str] = []
    types, functions, members_by_type, packages = source_surface(source_root)
    callable_signatures: dict[tuple[str, str], list[str]] = {}
    function_signatures: dict[tuple[str, str], list[str]] = {}
    for path in sorted(source_root.rglob("*.cj")):
        if path.name.endswith("_test.cj"):
            continue
        text = path.read_text(encoding="utf-8")
        package_match = PACKAGE.search(text)
        if package_match is None:
            continue
        package_key = _package_key(package_match.group(1))
        for type_name, signatures in _callable_signatures(text).items():
            callable_signatures.setdefault((package_key, type_name), []).extend(signatures)
        for function_name, signatures in _top_level_function_signatures(text).items():
            function_signatures.setdefault((package_key, function_name), []).extend(signatures)

    for package_key in sorted(packages):
        if package_key == "text" and not any(package == package_key for package, _ in types):
            continue
        package_docs = _package_docs(api_root, package_key)
        index = package_docs / "index.md"
        if not index.is_file():
            failures.append(f"missing package index for sdl{'.' + package_key if package_key else ''}: {index}")

    for package_key, name in sorted(types):
        package_docs = _package_docs(api_root, package_key)
        page = package_docs / f"{name}.md"
        index = package_docs / "index.md"
        qualified = f"sdl{'.' + package_key if package_key else ''}.{name}"
        if not page.is_file():
            failures.append(f"missing API page for {qualified}: {page}")
            continue
        page_text = page.read_text(encoding="utf-8")
        normalized_page = _normalize_signature(page_text)
        if re.search(rf"(?m)^#\s+{re.escape(name)}\s*$", page_text) is None:
            failures.append(f"API page has no '# {name}' heading: {page}")
        if re.search(rf"public\s+(?:open\s+)?(?:class|interface|struct|enum)\s+{re.escape(name)}\b", page_text) is None:
            failures.append(f"API page has no public declaration for {qualified}: {page}")
        for (kind, member), count in sorted(members_by_type.get((package_key, name), {}).items()):
            if kind in {"init", "func", "operator"}:
                documented = _documented_callable_count(page_text, kind, member)
                if documented < count:
                    failures.append(
                        f"API page documents {documented}/{count} overloads for {qualified}.{member}: {page}"
                    )
            elif re.search(rf"\b{re.escape(member)}\b", page_text) is None:
                failures.append(f"API page omits public member {qualified}.{member}: {page}")
        for signature in callable_signatures.get((package_key, name), []):
            if signature not in normalized_page:
                failures.append(f"API page omits or changes signature '{signature}' for {qualified}: {page}")
        if not index.is_file() or f"]({name}.md)" not in index.read_text(encoding="utf-8"):
            failures.append(f"package index does not link {name}.md: {index}")

    for (package_key, name), count in sorted(functions.items()):
        package_docs = _package_docs(api_root, package_key)
        functions_page = package_docs / "functions.md"
        index = package_docs / "index.md"
        qualified = f"sdl{'.' + package_key if package_key else ''}.{name}"
        if not functions_page.is_file():
            failures.append(f"missing function reference for {qualified}")
            continue
        text = functions_page.read_text(encoding="utf-8")
        normalized_page = _normalize_signature(text)
        if re.search(rf"(?m)^###\s+{re.escape(name)}\s*$", text) is None:
            failures.append(f"function reference has no heading for {qualified}")
        if len(re.findall(rf"\bpublic\s+func\s+{re.escape(name)}\b", text)) < count:
            failures.append(f"function reference omits an overload for {qualified}")
        for signature in function_signatures.get((package_key, name), []):
            if signature not in normalized_page:
                failures.append(f"function reference omits or changes signature '{signature}' for {qualified}")
        if not index.is_file() or f"](functions.md#{name.lower()})" not in index.read_text(encoding="utf-8"):
            failures.append(f"package index does not link {qualified}")

    documented_types = set()
    if api_root.is_dir():
        for page in api_root.rglob("*.md"):
            if page.name in SPECIAL_PAGES:
                continue
            package_key = ".".join(page.parent.relative_to(api_root).parts)
            documented_types.add((package_key, page.stem))
    for package_key, name in sorted(documented_types - types):
        failures.append(f"stale API page without a public type: {package_key or 'sdl'}/{name}.md")

    root_index = api_root.parent / "index.md"
    if root_index.is_file():
        text = root_index.read_text(encoding="utf-8")
        for package_key in sorted(package for package in packages if package != "text"):
            target = "sdl/index.md" if not package_key else f"sdl/{package_key.replace('.', '/')}/index.md"
            if f"]({target})" not in text:
                failures.append(f"API root index does not link package sdl{'.' + package_key if package_key else ''}")
    return failures
