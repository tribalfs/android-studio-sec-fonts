import sys
import xml.etree.ElementTree as ET

main_file = sys.argv[1]
patch_file = sys.argv[2]

def find_family_container(root):
    # Preferred: <familyset>
    node = root.find("familyset")
    if node is not None:
        return node

    # Fallback: root itself contains <family>
    if root.findall("family"):
        return root

    # Last fallback: search deeper
    for elem in root.iter():
        if elem.findall("family"):
            return elem

    return None


try:
    tree_main = ET.parse(main_file)
    root_main = tree_main.getroot()

    tree_patch = ET.parse(patch_file)
    root_patch = tree_patch.getroot()

    main_container = find_family_container(root_main)

    if main_container is None:
        print(f"⚠ SKIPPED: No valid container in {main_file}")
        sys.exit(0)

    existing = {ET.tostring(e) for e in main_container.findall("family")}

    added = 0
    for fam in root_patch.findall("family"):
        raw = ET.tostring(fam)
        if raw not in existing:
            main_container.append(fam)
            added += 1

    tree_main.write(main_file, encoding="utf-8", xml_declaration=True)

    print(f"✔ {main_file}: Added {added} families")

except Exception as e:
    print(f"❌ Failed processing {main_file}: {e}")