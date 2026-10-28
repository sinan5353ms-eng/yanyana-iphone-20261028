"""Check the generated project on Windows/macOS. This does NOT compile Swift."""
from pathlib import Path
import json
import os
import plistlib
import re
import struct
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
if os.name == "nt" and not str(ROOT).startswith("\\\\?\\"):
    ROOT = Path("\\\\?\\" + str(ROOT))
text = (ROOT / "YanYana.xcodeproj/project.pbxproj").read_text(encoding="utf-8")
tokens = re.findall(r'//[^\n]*|/\*.*?\*/|"(?:\\.|[^"\\])*"|[{}()=;,]|[^\s{}()=;,]+', text, re.S)
tokens = [t for t in tokens if not t.startswith(("//", "/*"))]
position = 0


def take(expected=None):
    global position
    value = tokens[position]
    position += 1
    if expected is not None:
        assert value == expected, (value, expected)
    return value


def parse():
    if tokens[position] == "{":
        take("{")
        value = {}
        while tokens[position] != "}":
            key = parse()
            take("=")
            assert key not in value, f"Duplicate key: {key}"
            value[key] = parse()
            take(";")
        take("}")
        return value
    if tokens[position] == "(":
        take("(")
        value = []
        while tokens[position] != ")":
            value.append(parse())
            take(",")
        take(")")
        return value
    value = take()
    return json.loads(value) if value.startswith('"') else value


project = parse()
assert position == len(tokens), "Unparsed project content"
objects = project["objects"]
assert objects[project["rootObject"]]["isa"] == "PBXProject"
scalar_refs = {"fileRef", "containerPortal", "target", "targetProxy", "productReference",
               "buildConfigurationList", "mainGroup", "productRefGroup", "remoteGlobalIDString"}
list_refs = {"children", "targets", "buildPhases", "buildRules", "dependencies", "buildConfigurations", "files"}
for object_id, obj in objects.items():
    assert re.fullmatch(r"[A-F0-9]{24}", object_id)
    for key, value in obj.items():
        if key in scalar_refs:
            assert value in objects, (object_id, key, value)
        if key in list_refs:
            assert all(v in objects for v in value), (object_id, key)
    if obj["isa"] == "PBXFileReference" and obj["sourceTree"] == "<group>":
        assert (ROOT / obj["path"]).exists(), obj["path"]

targets = {obj["name"]: obj for obj in objects.values() if obj["isa"] == "PBXNativeTarget"}
assert set(targets) == {"YanYana", "YanYanaKeyboard", "YanYanaTests"}
copy_phases = [objects[p] for p in targets["YanYana"]["buildPhases"] if objects[p]["isa"] == "PBXCopyFilesBuildPhase"]
assert len(copy_phases) == 1 and copy_phases[0]["dstSubfolderSpec"] == "13"
embedded = objects[objects[copy_phases[0]["files"][0]]["fileRef"]]
assert embedded["path"] == "YanYanaKeyboard.appex"

keyboard = plistlib.loads((ROOT / "Keyboard/Info.plist").read_bytes())
extension = keyboard["NSExtension"]
assert extension["NSExtensionPointIdentifier"] == "com.apple.keyboard-service"
assert extension["NSExtensionPrincipalClass"] == "$(PRODUCT_MODULE_NAME).KeyboardViewController"
assert extension["NSExtensionAttributes"]["PrimaryLanguage"] == "tr-TR"
for path in ROOT.rglob("*.plist"):
    plistlib.loads(path.read_bytes())
for path in ROOT.rglob("*.xcprivacy"):
    privacy = plistlib.loads(path.read_bytes())
    assert privacy["NSPrivacyTracking"] is False
    assert privacy["NSPrivacyCollectedDataTypes"] == []

scheme = ET.parse(ROOT / "YanYana.xcodeproj/xcshareddata/xcschemes/YanYana.xcscheme")
for ref in scheme.iter("BuildableReference"):
    assert ref.attrib["BlueprintIdentifier"] in objects
assert len(list(scheme.iter("TestableReference"))) == 1
for path in ROOT.rglob("*.json"):
    json.loads(path.read_text())
icon = (ROOT / "App/Assets.xcassets/AppIcon.appiconset/AppIcon.png").read_bytes()
assert icon[:8] == b"\x89PNG\r\n\x1a\n"
assert struct.unpack(">II", icon[16:24]) == (1024, 1024)
assert icon[25] == 2, "Icon should be RGB with no alpha"
sources = "\n".join(p.read_text(encoding="utf-8") for folder in ["App", "Keyboard", "Shared"]
                    for p in (ROOT / folder).rglob("*.swift"))
assert "URLSession" not in sources and "http://" not in sources and "https://" not in sources
assert "pt_BR" in sources
assert "TranslationSession(installedSource:" in sources
print(f"PASS: {len(objects)} Xcode objects; all references, source files, plists, scheme and icon checked.")
print("LIMIT: Swift compilation, XCTest execution and real-iPhone translation were not run here.")
