import os
import re

def get_relative_path(from_file, to_file):
    from_dir = os.path.dirname(from_file)
    rel_path = os.path.relpath(to_file, from_dir)
    return rel_path.replace("\\", "/")

lib_dir = os.path.abspath("lib")
constants_file = os.path.join(lib_dir, "core", "utils", "constants.dart")

for root, _, files in os.walk(lib_dir):
    for file in files:
        if file.endswith(".dart"):
            file_path = os.path.join(root, file)
            with open(file_path, "r", encoding="utf-8") as f:
                content = f.read()

            if "'http://localhost:5000" in content:
                # Replace url
                new_content = content.replace("'http://localhost:5000", "'${AppConstants.apiBaseUrl}")
                
                # Check import
                rel_path = get_relative_path(file_path, constants_file)
                import_stmt = f"import '{rel_path}';"
                
                if import_stmt not in new_content and "AppConstants" not in new_content:
                    # Find last import
                    lines = new_content.split('\n')
                    last_import_idx = -1
                    for i, line in enumerate(lines):
                        if line.startswith("import "):
                            last_import_idx = i
                    
                    if last_import_idx != -1:
                        lines.insert(last_import_idx + 1, import_stmt)
                    else:
                        lines.insert(0, import_stmt)
                    
                    new_content = '\n'.join(lines)
                elif "AppConstants" in new_content and import_stmt not in new_content:
                    # It might already have the import under a different name or path? Let's just add it if missing and hope for best, but AppConstants might be imported elsewhere.
                    # Let's add it if 'core/utils/constants.dart' is not in the file
                    if "constants.dart" not in new_content:
                        lines = new_content.split('\n')
                        last_import_idx = -1
                        for i, line in enumerate(lines):
                            if line.startswith("import "):
                                last_import_idx = i
                        
                        if last_import_idx != -1:
                            lines.insert(last_import_idx + 1, import_stmt)
                        else:
                            lines.insert(0, import_stmt)
                        
                        new_content = '\n'.join(lines)

                with open(file_path, "w", encoding="utf-8") as f:
                    f.write(new_content)
                print(f"Fixed {file_path}")
