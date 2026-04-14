import os
import re

def clean_file(filepath):
    if not filepath.endswith('.swift') and not filepath.endswith('.plist'):
        return
        
    with open(filepath, 'r') as f:
        lines = f.readlines()
    
    new_lines = []
    
    # 1. Skip standard Xcode header blocks at the top
    i = 0
    # A header block usually starts with // and contains FileName, ProjectName, Created by, etc.
    # We skip all leading // lines until we hit something else
    while i < len(lines) and lines[i].strip().startswith('//'):
        i += 1
    
    # Skip trailing empty lines after header
    if i > 0:
        while i < len(lines) and lines[i].strip() == '':
            i += 1
    else:
        i = 0 # No header block found

    # 2. Process the rest of the file
    for j in range(i, len(lines)):
        line = lines[j]
        
        # Keep documentation comments (starting with ///)
        if line.strip().startswith('///'):
            new_lines.append(line)
            continue
            
        # Remove lines that are just single-line comments // ...
        # This covers logic notes, tutorial steps, and leftovers
        if line.strip().startswith('//'):
            # Check if it contains metadata or dates we MUST remove
            # (Though we are removing all // anyway based on "unwanted comment")
            continue
            
        # Check for trailing comments on code lines and scrub metadata from them
        if '//' in line:
            parts = line.split('//', 1)
            code_part = parts[0]
            comment_part = parts[1]
            # Scrub dates and creation info from trailing comments
            if re.search(r'Created|Copyright|202[0-9]|Dhruv', comment_part, re.IGNORECASE):
                new_lines.append(code_part.rstrip() + '\n')
            else:
                # Keep other trailing comments for now as they might be short explanations
                new_lines.append(line)
            continue
            
        new_lines.append(line)

    # Remove trailing empty lines and ensure single newline at EOF
    while new_lines and new_lines[-1].strip() == '':
        new_lines.pop()
    if new_lines:
        new_lines.append('\n')

    with open(filepath, 'w') as f:
        f.writelines(new_lines)

# Directories to search
project_root = "/Users/DhruvPatel/iOS Developer/NewsDigest"
exclude_dirs = {'.git', '.xcodeproj', 'Screenshots'}

for root, dirs, files in os.walk(project_root):
    dirs[:] = [d for d in dirs if d not in exclude_dirs]
    for file in files:
        if file.endswith('.swift') or file.endswith('.plist') or file.endswith('.md'):
            clean_file(os.path.join(root, file))

print("Cleanup complete.")
