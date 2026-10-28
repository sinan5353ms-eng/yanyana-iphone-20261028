"""Create a dependency-free, directly openable Xcode project. Python standard library only."""
from pathlib import Path
import hashlib
import json
import os
import plistlib
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
if os.name == "nt" and not str(ROOT).startswith("\\\\?\\"):
    ROOT = Path("\\\\?\\" + str(ROOT))
objects = {}


def oid(name):
    return hashlib.sha256(name.encode()).hexdigest()[:24].upper()


def add(object_name, **values):
    key = oid(object_name)
    objects[key] = values
    return key


def plist(path, value):
    destination = ROOT / path
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_bytes(plistlib.dumps(value, sort_keys=False))


common_info = {
    "CFBundleDevelopmentRegion": "tr",
    "CFBundleExecutable": "$(EXECUTABLE_NAME)",
    "CFBundleIdentifier": "$(PRODUCT_BUNDLE_IDENTIFIER)",
    "CFBundleInfoDictionaryVersion": "6.0",
    "CFBundleName": "$(PRODUCT_NAME)",
    "CFBundleShortVersionString": "1.0",
    "CFBundleVersion": "1",
}
plist("App/Info.plist", {
    **common_info, "CFBundlePackageType": "APPL", "CFBundleDisplayName": "YanYana",
    "LSRequiresIPhoneOS": True,
    "UILaunchScreen": {},
    "UIApplicationSceneManifest": {"UIApplicationSupportsMultipleScenes": False},
    "UISupportedInterfaceOrientations": ["UIInterfaceOrientationPortrait",
        "UIInterfaceOrientationLandscapeLeft", "UIInterfaceOrientationLandscapeRight"],
})
plist("Keyboard/Info.plist", {
    **common_info, "CFBundlePackageType": "XPC!", "CFBundleDisplayName": "YanYana",
    "NSExtension": {
        "NSExtensionPointIdentifier": "com.apple.keyboard-service",
        "NSExtensionPrincipalClass": "$(PRODUCT_MODULE_NAME).KeyboardViewController",
        "NSExtensionAttributes": {
            "IsASCIICapable": True, "PrimaryLanguage": "tr-TR",
            "PrefersRightToLeft": False, "RequestsOpenAccess": True,
        },
    },
})
for folder in ("App", "Keyboard"):
    plist(f"{folder}/PrivacyInfo.xcprivacy", {
        "NSPrivacyTracking": False,
        "NSPrivacyTrackingDomains": [],
        "NSPrivacyCollectedDataTypes": [],
        "NSPrivacyAccessedAPITypes": [],
    })


def file(path, kind):
    return add(f"file:{path}", isa="PBXFileReference", lastKnownFileType=kind,
               path=path, sourceTree="<group>")


source_paths = ["App/YanYanaApp.swift", "Shared/TranslationCore.swift",
                "Shared/ComposerModel.swift", "Keyboard/KeyboardView.swift",
                "Keyboard/KeyboardViewController.swift", "Tests/ComposerModelTests.swift"]
refs = {path: file(path, "sourcecode.swift") for path in source_paths}
for path in ["App/Info.plist", "Keyboard/Info.plist", "App/PrivacyInfo.xcprivacy",
             "Keyboard/PrivacyInfo.xcprivacy"]:
    refs[path] = file(path, "text.xml")
refs["README.md"] = file("README.md", "net.daringfireball.markdown")

products = {}
for name, ext, kind in [("YanYana", "app", "wrapper.application"),
                         ("YanYanaKeyboard", "appex", "wrapper.app-extension"),
                         ("YanYanaTests", "xctest", "wrapper.cfbundle")]:
    products[name] = add(f"product:{name}", isa="PBXFileReference", explicitFileType=kind,
                         includeInIndex=0, path=f"{name}.{ext}", sourceTree="BUILT_PRODUCTS_DIR")
product_group = add("products", isa="PBXGroup", children=list(products.values()),
                    name="Products", sourceTree="<group>")
groups = []
for folder in ["App", "Keyboard", "Shared", "Tests"]:
    groups.append(add(f"group:{folder}", isa="PBXGroup", name=folder, sourceTree="<group>",
                      children=[ref for path, ref in refs.items() if path.startswith(folder + "/")]))
main_group = add("main", isa="PBXGroup", children=groups + [refs["README.md"], product_group],
                 sourceTree="<group>")


def configs(name, settings):
    entries = []
    for mode in ("Debug", "Release"):
        config = dict(settings)
        config.update({"SWIFT_OPTIMIZATION_LEVEL": "-Onone" if mode == "Debug" else "-O",
                       "DEBUG_INFORMATION_FORMAT": "dwarf" if mode == "Debug" else "dwarf-with-dsym"})
        if mode == "Debug":
            config["SWIFT_ACTIVE_COMPILATION_CONDITIONS"] = "DEBUG"
            config["ENABLE_TESTABILITY"] = "YES"
        entries.append(add(f"config:{name}:{mode}", isa="XCBuildConfiguration",
                           buildSettings=config, name=mode))
    return add(f"configs:{name}", isa="XCConfigurationList", buildConfigurations=entries,
               defaultConfigurationIsVisible=0, defaultConfigurationName="Release")


project_config = configs("project", {
    "SDKROOT": "iphoneos", "IPHONEOS_DEPLOYMENT_TARGET": "26.0", "SWIFT_VERSION": "5.0",
    "CLANG_ENABLE_MODULES": "YES", "CLANG_ENABLE_OBJC_ARC": "YES",
    "CODE_SIGN_STYLE": "Automatic", "TARGETED_DEVICE_FAMILY": "1",
    "SUPPORTED_PLATFORMS": "iphoneos iphonesimulator", "ENABLE_USER_SCRIPT_SANDBOXING": "YES",
})


def phase(name, isa, paths):
    build_files = [add(f"build:{name}:{path}", isa="PBXBuildFile", fileRef=refs[path]) for path in paths]
    return add(name, isa=isa, buildActionMask=2147483647, files=build_files,
               runOnlyForDeploymentPostprocessing=0)


shared = ["Shared/TranslationCore.swift", "Shared/ComposerModel.swift"]
target_specs = [
    ("YanYana", "com.apple.product-type.application", ["App/YanYanaApp.swift"] + shared,
     "App", "app.local.yanyana", {}),
    ("YanYanaKeyboard", "com.apple.product-type.app-extension",
     ["Keyboard/KeyboardView.swift", "Keyboard/KeyboardViewController.swift"] + shared,
     "Keyboard", "app.local.yanyana.keyboard", {"APPLICATION_EXTENSION_API_ONLY": "YES", "SKIP_INSTALL": "YES"}),
    ("YanYanaTests", "com.apple.product-type.bundle.unit-test", ["Tests/ComposerModelTests.swift"],
     None, "app.local.yanyana.tests", {"GENERATE_INFOPLIST_FILE": "YES",
         "TEST_HOST": "$(BUILT_PRODUCTS_DIR)/YanYana.app/YanYana", "BUNDLE_LOADER": "$(TEST_HOST)"}),
]
targets = []
for name, kind, sources, folder, bundle, extra in target_specs:
    phases = [phase(f"sources:{name}", "PBXSourcesBuildPhase", sources),
              phase(f"frameworks:{name}", "PBXFrameworksBuildPhase", [])]
    if folder:
        phases.append(phase(f"resources:{name}", "PBXResourcesBuildPhase", [f"{folder}/PrivacyInfo.xcprivacy"]))
    settings = {
        "PRODUCT_NAME": "$(TARGET_NAME)", "PRODUCT_BUNDLE_IDENTIFIER": bundle,
        "LD_RUNPATH_SEARCH_PATHS": ["$(inherited)", "@executable_path/Frameworks", "@executable_path/../../Frameworks"],
        **extra,
    }
    if folder:
        settings["INFOPLIST_FILE"] = f"{folder}/Info.plist"
    if name == "YanYana":
        settings["ASSETCATALOG_COMPILER_APPICON_NAME"] = "AppIcon"
    targets.append(add(f"target:{name}", isa="PBXNativeTarget", name=name, productName=name,
                       productType=kind, productReference=products[name],
                       buildConfigurationList=configs(name, settings), buildPhases=phases,
                       buildRules=[], dependencies=[]))


def dependency(from_name, to_name):
    proxy = add(f"proxy:{from_name}:{to_name}", isa="PBXContainerItemProxy", containerPortal=oid("project"),
                proxyType=1, remoteGlobalIDString=oid(f"target:{to_name}"), remoteInfo=to_name)
    dep = add(f"dependency:{from_name}:{to_name}", isa="PBXTargetDependency",
              target=oid(f"target:{to_name}"), targetProxy=proxy)
    objects[oid(f"target:{from_name}")]["dependencies"].append(dep)


dependency("YanYana", "YanYanaKeyboard")
dependency("YanYanaTests", "YanYana")
embed_file = add("embed:keyboard", isa="PBXBuildFile", fileRef=products["YanYanaKeyboard"],
                 settings={"ATTRIBUTES": ["RemoveHeadersOnCopy"]})
embed_phase = add("embed", isa="PBXCopyFilesBuildPhase", buildActionMask=2147483647, dstPath="",
                  dstSubfolderSpec=13, files=[embed_file], name="Embed App Extensions",
                  runOnlyForDeploymentPostprocessing=0)
objects[oid("target:YanYana")]["buildPhases"].append(embed_phase)

# A native icon is generated without external packages or downloaded artwork.
asset_dir = ROOT / "App/Assets.xcassets"
asset_dir.mkdir(parents=True, exist_ok=True)
(asset_dir / "Contents.json").write_text(json.dumps({"info": {"version": 1, "author": "xcode"}}))
icon_dir = asset_dir / "AppIcon.appiconset"
icon_dir.mkdir(exist_ok=True)
import struct
import zlib
pixels = bytearray()
for y in range(1024):
    pixels.append(0)
    for x in range(1024):
        # Two white message bubbles on a forest green background, with small tails.
        first = 195 <= x < 620 and 245 <= y < 570
        second = 465 <= x < 830 and 510 <= y < 785
        tail1 = 245 <= x <= 340 and 570 <= y <= 650 and x - 245 < 650 - y
        tail2 = 705 <= x <= 785 and 785 <= y <= 850 and 785 - x < 850 - y
        color = (246, 247, 238) if first or tail1 else ((177, 220, 195) if second or tail2 else (21, 87, 69))
        pixels.extend(color)


def chunk(kind, data):
    return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data) & 0xFFFFFFFF)


png = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", 1024, 1024, 8, 2, 0, 0, 0))
png += chunk(b"IDAT", zlib.compress(bytes(pixels), 9)) + chunk(b"IEND", b"")
(icon_dir / "AppIcon.png").write_bytes(png)
(icon_dir / "Contents.json").write_text(json.dumps({"images": [
    {"filename": "AppIcon.png", "idiom": "universal", "platform": "ios", "size": "1024x1024"}],
    "info": {"author": "xcode", "version": 1}}))
refs["App/Assets.xcassets"] = file("App/Assets.xcassets", "folder.assetcatalog")
objects[oid("group:App")]["children"].append(refs["App/Assets.xcassets"])
icon_file = add("build:icons", isa="PBXBuildFile", fileRef=refs["App/Assets.xcassets"])
objects[oid("resources:YanYana")]["files"].append(icon_file)

project_id = add("project", isa="PBXProject", attributes={"LastUpgradeCheck": "2600",
    "BuildIndependentTargetsInParallel": "YES"}, buildConfigurationList=project_config,
    compatibilityVersion="Xcode 14.0", developmentRegion="tr", knownRegions=["tr", "en", "Base"],
    mainGroup=main_group, productRefGroup=product_group, projectDirPath="", projectRoot="", targets=targets)


def serialize(value, indent=0):
    tab = "\t" * indent
    if isinstance(value, dict):
        return "{\n" + "".join(f"{tab}\t{serialize(k)} = {serialize(v, indent + 1)};\n" for k, v in value.items()) + tab + "}"
    if isinstance(value, list):
        return "(\n" + "".join(f"{tab}\t{serialize(item, indent + 1)},\n" for item in value) + tab + ")"
    if isinstance(value, int):
        return str(value)
    return json.dumps(value, ensure_ascii=False)


project_folder = ROOT / "YanYana.xcodeproj"
project_folder.mkdir(exist_ok=True)
(project_folder / "project.pbxproj").write_text("// !$*UTF8*$!\n" + serialize({
    "archiveVersion": 1, "classes": {}, "objectVersion": 56,
    "objects": objects, "rootObject": project_id}) + "\n", encoding="utf-8")
workspace = project_folder / "project.xcworkspace"
workspace.mkdir(exist_ok=True)
(workspace / "contents.xcworkspacedata").write_text(
    '<?xml version="1.0" encoding="UTF-8"?><Workspace version="1.0"><FileRef location="self:"></FileRef></Workspace>')

scheme = ET.Element("Scheme", LastUpgradeVersion="2600", version="1.3")


def build_ref(parent, name):
    ET.SubElement(parent, "BuildableReference", BuildableIdentifier="primary",
                  BlueprintIdentifier=oid(f"target:{name}"),
                  BuildableName="YanYana.app" if name == "YanYana" else "YanYanaTests.xctest",
                  BlueprintName=name, ReferencedContainer="container:YanYana.xcodeproj")


build_action = ET.SubElement(scheme, "BuildAction", parallelizeBuildables="YES", buildImplicitDependencies="YES")
entries = ET.SubElement(build_action, "BuildActionEntries")
entry = ET.SubElement(entries, "BuildActionEntry", buildForTesting="YES", buildForRunning="YES",
                      buildForProfiling="YES", buildForArchiving="YES", buildForAnalyzing="YES")
build_ref(entry, "YanYana")
test_action = ET.SubElement(scheme, "TestAction", buildConfiguration="Debug",
                           selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB",
                           selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB", shouldUseLaunchSchemeArgsEnv="YES")
testable = ET.SubElement(ET.SubElement(test_action, "Testables"), "TestableReference", skipped="NO")
build_ref(testable, "YanYanaTests")
launch = ET.SubElement(scheme, "LaunchAction", buildConfiguration="Debug",
                      selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB",
                      selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB", launchStyle="0",
                      useCustomWorkingDirectory="NO", ignoresPersistentStateOnLaunch="NO",
                      debugDocumentVersioning="YES", allowLocationSimulation="YES")
build_ref(ET.SubElement(launch, "BuildableProductRunnable", runnableDebuggingMode="0"), "YanYana")
profile = ET.SubElement(scheme, "ProfileAction", buildConfiguration="Release", shouldUseLaunchSchemeArgsEnv="YES",
                       savedToolIdentifier="", useCustomWorkingDirectory="NO", debugDocumentVersioning="YES")
build_ref(ET.SubElement(profile, "BuildableProductRunnable", runnableDebuggingMode="0"), "YanYana")
ET.SubElement(scheme, "AnalyzeAction", buildConfiguration="Debug")
ET.SubElement(scheme, "ArchiveAction", buildConfiguration="Release", revealArchiveInOrganizer="YES")
scheme_path = project_folder / "xcshareddata/xcschemes/YanYana.xcscheme"
scheme_path.parent.mkdir(parents=True, exist_ok=True)
ET.indent(scheme)
ET.ElementTree(scheme).write(scheme_path, encoding="utf-8", xml_declaration=True)
print("Xcode project, scheme, plists and icon generated.")
