#!/usr/bin/env python3
"""
Genere Depli2D.xcodeproj/project.pbxproj de facon deterministe (sans Xcode).

Usage :
    python3 Scripts/make_xcodeproj.py [--out DIR]

Par defaut, DIR est la racine du depot (parent de Scripts/). Le projet est
ecrit dans DIR/Depli2D.xcodeproj et les sources vivent dans DIR/Depli2D/.
Le script verifie que chaque UUID reference est bien defini et que chaque
fichier reference existe sur le disque.
"""

import argparse
import os
import re
import sys

SRC_GROUPS = [
    (None, ["Depli2DApp.swift", "SceneDelegate.swift", "Info.plist"]),
    ("Models", ["ElementKind.swift", "DelineElement.swift", "DielineDocument.swift", "PackagingTemplates.swift"]),
    ("ViewModels", ["EditorViewModel.swift"]),
    ("Views", ["ContentView.swift", "CanvasView.swift", "InspectorBar.swift", "TemplateSheet.swift",
               "DielineShape.swift", "DocumentPreview.swift", "ActivityView.swift"]),
    ("Utils", ["Geometry.swift", "PDFExport.swift"]),
]

APP_NAME = "Depli2D"
BUNDLE_ID = "com.vibe.depli2d"
DEPLOYMENT_TARGET = "17.0"


class IdGen:
    def __init__(self):
        self.n = 0

    def __call__(self):
        self.n += 1
        return "D2D%021d" % self.n  # 24 caracteres hexadecimaux


def children_block(pairs):
    return "".join("\t\t\t\t%s /* %s */,\n" % (i, name) for i, name in pairs)


def target_settings_common():
    return """\t\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\t\tGENERATE_INFOPLIST_FILE = NO;
\t\t\t\t\tINFOPLIST_FILE = Depli2D/Info.plist;
\t\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = %s;
\t\t\t\t\tLD_RUNPATH_SEARCH_PATHS = (
\t\t\t\t\t\t"$(inherited)",
\t\t\t\t\t\t"@executable_path/Frameworks",
\t\t\t\t\t);
\t\t\t\t\tMARKETING_VERSION = 1.0;
\t\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = "%s";
\t\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\t\tSWIFT_EMIT_LOC_STRINGS = NO;
\t\t\t\t\tSWIFT_VERSION = 5.0;
\t\t\t\t\tTARGETED_DEVICE_FAMILY = "1,2";
""" % (DEPLOYMENT_TARGET, BUNDLE_ID)


def generate(out_dir):
    g = IdGen()
    project_id = g()
    main_group = g()
    products_group = g()
    app_ref = g()
    target_id = g()
    sources_phase = g()
    frameworks_phase = g()
    resources_phase = g()
    cfg_project = g()
    cfg_target = g()
    proj_debug = g()
    proj_release = g()
    tgt_debug = g()
    tgt_release = g()
    app_group = g()

    fileref_lines = []
    buildfile_lines = []
    sources_files = []
    group_blocks = []
    app_children = []

    for sub, files in SRC_GROUPS:
        child = []
        for f in files:
            path_on_disk = os.path.join(out_dir, "Depli2D", sub or "", f)
            if not os.path.isfile(path_on_disk):
                sys.exit("Fichier manquant: %s" % path_on_disk)
            ref = g()
            if f.endswith(".swift"):
                fileref_lines.append(
                    '\t\t%s /* %s */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; '
                    'path = %s; sourceTree = "<group>"; };\n' % (ref, f, f))
                bf = g()
                buildfile_lines.append(
                    '\t\t%s /* %s in Sources */ = {isa = PBXBuildFile; fileRef = %s /* %s */; };\n'
                    % (bf, f, ref, f))
                sources_files.append((bf, f))
            else:
                fileref_lines.append(
                    '\t\t%s /* %s */ = {isa = PBXFileReference; lastKnownFileType = text.plist.xml; '
                    'path = %s; sourceTree = "<group>"; };\n' % (ref, f, f))
            child.append((ref, f))
        if sub is None:
            app_children.extend(child)
        else:
            gid = g()
            group_blocks.append(
                '\t\t%s /* %s */ = {\n\t\t\tisa = PBXGroup;\n\t\t\tchildren = (\n%s\t\t\t);\n'
                '\t\t\tpath = %s;\n\t\t\tsourceTree = "<group>";\n\t\t};\n'
                % (gid, sub, children_block(child), sub))
            app_children.append((gid, sub))

    app_group_block = (
        '\t\t%s /* Depli2D */ = {\n\t\t\tisa = PBXGroup;\n\t\t\tchildren = (\n%s\t\t\t);\n'
        '\t\t\tpath = Depli2D;\n\t\t\tsourceTree = "<group>";\n\t\t};\n'
        % (app_group, children_block(app_children)))

    settings = target_settings_common()

    text = """// !$*UTF8*$!
{
\tarchiveVersion = 1;
\tclasses = {
\t};
\tobjectVersion = 56;
\tobjects = {

/* Begin PBXBuildFile section */
%s/* End PBXBuildFile section */

/* Begin PBXFileReference section */
\t\t%s /* %s.app */ = {explicitFileType = wrapper.application; includeInIndex = 0; path = %s.app; sourceTree = BUILT_PRODUCTS_DIR; };
%s/* End PBXFileReference section */

/* Begin PBXFrameworksBuildPhase section */
\t\t%s /* Frameworks */ = {
\t\t\tisa = PBXFrameworksBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t};
/* End PBXFrameworksBuildPhase section */

/* Begin PBXGroup section */
\t\t%s /* main */ = {
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t%s /* Depli2D */,
\t\t\t\t%s /* Products */,
\t\t\t);
\t\t\tsourceTree = "<group>";
\t\t};
\t\t%s /* Products */ = {
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t%s /* %s.app */,
\t\t\t);
\t\t\tname = Products;
\t\t\tsourceTree = "<group>";
\t\t};
%s%s/* End PBXGroup section */

/* Begin PBXNativeTarget section */
\t\t%s /* %s */ = {
\t\t\tisa = PBXNativeTarget;
\t\t\tbuildConfigurationList = %s /* Build configuration list for PBXNativeTarget "%s" */;
\t\t\tbuildPhases = (
\t\t\t\t%s /* Sources */,
\t\t\t\t%s /* Frameworks */,
\t\t\t\t%s /* Resources */,
\t\t\t);
\t\t\tbuildRules = (
\t\t\t);
\t\t\tdependencies = (
\t\t\t);
\t\t\tname = %s;
\t\t\tproductName = %s;
\t\t\tproductReference = %s /* %s.app */;
\t\t\tproductType = "com.apple.product-type.application";
\t\t};
/* End PBXNativeTarget section */

/* Begin PBXProject section */
\t\t%s /* Project object */ = {
\t\t\tisa = PBXProject;
\t\t\tattributes = {
\t\t\t\tLastUpgradeCheck = 1600;
\t\t\t};
\t\t\tbuildConfigurationList = %s /* Build configuration list for PBXProject "%s" */;
\t\t\tcompatibilityVersion = "Xcode 14.0";
\t\t\tdevelopmentRegion = en;
\t\t\thasScannedForEncodings = 0;
\t\t\tknownRegions = (
\t\t\t\ten,
\t\t\t\tfr,
\t\t\t\tBase,
\t\t\t);
\t\t\tmainGroup = %s /* main */;
\t\t\tproductRefGroup = %s /* Products */;
\t\t\tprojectDirPath = "";
\t\t\tprojectRoot = "";
\t\t\ttargets = (
\t\t\t\t%s /* %s */,
\t\t\t);
\t\t};
/* End PBXProject section */

/* Begin PBXResourcesBuildPhase section */
\t\t%s /* Resources */ = {
\t\t\tisa = PBXResourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t};
/* End PBXResourcesBuildPhase section */

/* Begin PBXSourcesBuildPhase section */
\t\t%s /* Sources */ = {
\t\t\tisa = PBXSourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
%s\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t};
/* End PBXSourcesBuildPhase section */

/* Begin XCBuildConfiguration section */
\t\t%s /* Debug */ = {
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {
\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tGENERATE_INFOPLIST_FILE = NO;
\t\t\t\tMARKETING_VERSION = 1.0;
\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = "-Onone";
\t\t\t\tSWIFT_VERSION = 5.0;
\t\t\t};
\t\t\tname = Debug;
\t\t};
\t\t%s /* Release */ = {
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {
\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tGENERATE_INFOPLIST_FILE = NO;
\t\t\t\tMARKETING_VERSION = 1.0;
\t\t\t\tSWIFT_VERSION = 5.0;
\t\t\t};
\t\t\tname = Release;
\t\t};
\t\t%s /* Debug */ = {
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {
%s
\t\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = "-Onone";
\t\t\t};
\t\t\tname = Debug;
\t\t};
\t\t%s /* Release */ = {
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {
%s
\t\t\t\t\tENABLE_NS_ASSERTIONS = NO;
\t\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = "-O";
\t\t\t};
\t\t\tname = Release;
\t\t};
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
\t\t%s /* Build configuration list for PBXProject "%s" */ = {
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = (
\t\t\t\t%s /* Debug */,
\t\t\t\t%s /* Release */,
\t\t\t);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t};
\t\t%s /* Build configuration list for PBXNativeTarget "%s" */ = {
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = (
\t\t\t\t%s /* Debug */,
\t\t\t\t%s /* Release */,
\t\t\t);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t};
/* End XCConfigurationList section */
\t};
\trootObject = %s /* Project object */;
}
""" % (
        "".join(buildfile_lines),
        app_ref, APP_NAME, APP_NAME,
        "".join(fileref_lines),
        frameworks_phase,
        main_group, app_group, products_group,
        products_group, app_ref, APP_NAME,
        app_group_block, "".join(group_blocks),
        target_id, APP_NAME, cfg_target, APP_NAME,
        sources_phase, frameworks_phase, resources_phase,
        APP_NAME, APP_NAME, app_ref, APP_NAME,
        project_id, cfg_project, APP_NAME, main_group, products_group, target_id, APP_NAME,
        resources_phase,
        sources_phase, children_block(sources_files),
        proj_debug,
        proj_release,
        tgt_debug, settings,
        tgt_release, settings,
        cfg_project, APP_NAME, proj_debug, proj_release,
        cfg_target, APP_NAME, tgt_debug, tgt_release,
        project_id,
    )

    return text


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--out", default=os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                        help="Dossier racine contenant Depli2D/ (defaut: racine du depot)")
    args = parser.parse_args()

    text = generate(args.out)

    defined = set(re.findall(r"^\t\t([0-9A-F]{24}) /\*", text, re.M))
    referenced = set(re.findall(r"\b([0-9A-F]{24})\b", text))
    missing = referenced - defined
    if missing:
        sys.exit("UUIDs references non definis: %s" % sorted(missing))

    proj_dir = os.path.join(args.out, APP_NAME + ".xcodeproj")
    os.makedirs(proj_dir, exist_ok=True)
    out_path = os.path.join(proj_dir, "project.pbxproj")
    with open(out_path, "w", encoding="utf-8") as fh:
        fh.write(text)
    print("Ecrit: %s (%d UUID definis, %d references verifiees)"
          % (out_path, len(defined), len(referenced)))


if __name__ == "__main__":
    main()
