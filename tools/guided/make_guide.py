"""Writes the Guided Mode guides (Phase 13) from their specs and research.

    python3 tools/guided/make_guide.py              every guide with a spec
    python3 tools/guided/make_guide.py cp_town      one guide
    python3 tools/guided/make_guide.py --check      compare, write nothing

A guide (mods/infinite_expansion/custom_scripts/ix/guided/guides/<map>.gsc)
is generated from two files here:

  research/<map>.md   what the map's main quest is, step by step, with the
                      stock scripts' file:line for every signal and marker
                      and the walkthroughs used (headings "### 3. <id>" or
                      "#### 3. id: <id>", fields "- objective:",
                      "- location:", "- hint_minimal:", "- hint_standard:",
                      "- hint_detailed:")
  specs/<map>.py      which steps the guide has, in order, and how each is
                      detected and marked: HEADER (map, map name, quest,
                      prerequisites), COMMENT (the file's comment lines),
                      STEPS, HELPERS (GSC after guide()) and optionally
                      GUIDE_EXTRA (GSC lines before guide()'s return)

A STEPS entry either uses a research step's texts ({"use": "<id>", ...}),
optionally overriding any of id, objective, location, minimal, standard,
detailed, or gives them all itself ({"id": ..., "objective": ...}). Every
entry has "detect" and "marker" and optionally "extra" (GSC lines after the
add_step: step.check, step.locate, step.parallel, step.needs ...). The texts
are checked against what the tracker shows (LIMITS) and made safe for a GSC
string. tools/tests/test_guides.py checks the result against the stock
scripts and that every generated guide matches its spec.

cp_zmb's guide is written by hand and has no spec.
"""
import importlib.util
import re
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[1]
GUIDES = REPO / "mods" / "infinite_expansion" / "custom_scripts" / "ix" / "guided" / "guides"
LIMITS = {"objective": 32, "location": 40, "minimal": 70, "standard": 150, "detailed": 300}
FIELDS = ("objective", "location", "hint_minimal", "hint_standard", "hint_detailed")


def research_steps(path):
    """The steps of a research file, by id: {id: {objective, location, hint_*}}."""
    text = path.read_text(encoding="utf-8")
    heads = list(re.finditer(r"^#{3,4} ([A-Z]?\d+[a-z]?)\. (?:id: )?([a-z0-9_]+)[^\n]*$", text, re.M))
    found = {}
    for n, head in enumerate(heads):
        end = heads[n + 1].start() if n + 1 < len(heads) else len(text)
        body = text[head.end():end]
        cut = re.search(r"^## ", body, re.M)
        if cut:
            body = body[:cut.start()]
        step = {}
        for field in FIELDS:
            match = re.search(r"^- \*{0,2}" + field + r":\*{0,2}[ \t]*(.*?)(?=^- \*{0,2}[a-z_]+:|\Z)", body, re.M | re.S)
            step[field] = re.sub(r"\s+", " ", match.group(1)).strip() if match else ""
        found[head.group(2)] = step
    return found


def clean(text):
    """A text as a GSC string can hold it, and as chat and iprintln show it."""
    text = text.replace('"', "'").replace("\\", "/").replace("%", " percent").replace("`", "")
    text = text.replace("->", "to").replace("’", "'").replace("—", ", ").replace("–", "-")
    return " ".join(text.split())


def gsc_string(text):
    assert '"' not in text and "\\" not in text, text
    return '"' + text + '"'


def load_spec(map_name):
    path = HERE / "specs" / f"{map_name}.py"
    loader = importlib.util.spec_from_file_location(f"spec_{map_name}", path)
    spec = importlib.util.module_from_spec(loader)
    loader.loader.exec_module(spec)
    return spec


def build(map_name):
    """The guide's GSC text, or raises ValueError listing what does not fit."""
    spec = load_spec(map_name)
    research = research_steps(HERE / "research" / f"{map_name}.md")
    lines = list(spec.COMMENT) + ["", "guide()", "{"]
    header = ", ".join(gsc_string(clean(value)) for value in spec.HEADER)
    lines.append(f"    guide = custom_scripts\\ix\\guided\\guided::new_guide( {header} );")
    problems = []

    for entry in spec.STEPS:
        texts = {}
        if "use" in entry:
            found = research[entry["use"]]
            texts = {"id": entry["use"], "objective": found["objective"], "location": found["location"],
                     "minimal": found["hint_minimal"], "standard": found["hint_standard"], "detailed": found["hint_detailed"]}
        for key in ("id", "objective", "location", "minimal", "standard", "detailed"):
            if key in entry:
                texts[key] = entry[key]
        texts = {key: clean(value) for key, value in texts.items()}
        for key, limit in LIMITS.items():
            if not texts[key]:
                problems.append(f"{texts['id']}: no {key}")
            elif len(texts[key]) > limit:
                problems.append(f"{texts['id']}: {key} is {len(texts[key])} > {limit}: {texts[key]}")
        args = [texts["id"], texts["objective"], texts["location"]]
        lines.append("")
        lines.append("    step = custom_scripts\\ix\\guided\\guided::add_step( guide, " + ", ".join(gsc_string(a) for a in args) + ",")
        lines.append("        " + gsc_string(texts["minimal"]) + ",")
        lines.append("        " + gsc_string(texts["standard"]) + ",")
        lines.append("        " + gsc_string(texts["detailed"]) + ",")
        lines.append("        " + gsc_string(entry["detect"]) + ", " + gsc_string(entry["marker"]) + " );")
        for extra in entry.get("extra", []):
            lines.append("    " + extra)

    extra = getattr(spec, "GUIDE_EXTRA", [])
    if extra:
        lines.append("")
        lines += ["    " + line for line in extra]
    lines += ["", "    return guide;", "}", ""]
    if problems:
        raise ValueError("\n".join(problems))
    return "\n".join(lines) + "\n" + spec.HELPERS.lstrip("\n")


def specs():
    return sorted(path.stem for path in (HERE / "specs").glob("cp_*.py"))


def main(argv):
    check = "--check" in argv
    names = [arg for arg in argv if not arg.startswith("--")] or specs()
    stale = []
    for map_name in names:
        text = build(map_name)
        out = GUIDES / f"{map_name}.gsc"
        if check:
            if not out.exists() or out.read_text(encoding="utf-8") != text:
                stale.append(map_name)
            continue
        out.write_text(text, encoding="utf-8", newline="")
        print(f"{out.relative_to(REPO)}: {text.count('add_step(')} steps")
    if stale:
        print("not as their specs make them: " + ", ".join(stale))
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
