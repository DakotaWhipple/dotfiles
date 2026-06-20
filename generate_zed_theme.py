#!/usr/bin/env python3
import json

# 1. Define your semantic color palette
PALETTE = {
    "google_blue": "#5494FEff",
    "google_red": "#F15C52ff",
    "google_yellow": "#FFD13Bff",
    "google_green": "#41CD7Dff",
    "orange": "#FF944Dff",
    "cyan": "#4DD0E1ff",
    "purple": "#B170FFff",
    "pink": "#FF73B9ff",
    "white": "#E8EAEDff",
    "gray": "#9AA0A6ff",
    "light_gray": "#BDC1C6ff"
}

# 2. Map Zed syntax keys to your semantic colors
# Add any font_style or font_weight as a tuple: (color_name, font_style, font_weight)
SYNTAX_MAPPING = {
    # Core Semantics
    "variable": 
        "google_green",
    "type": 
        "google_blue",
    "constructor": 
        "google_blue",
    "enum": 
        "google_blue",
    "tag": 
        "google_blue",
    "property": 
        "google_yellow",
    "attribute": 
        "google_red",
    "function": 
        "google_yellow",

    # Secondary / Hardcoded Data
    "string": 
        "google_green",
    "text.literal": 
        "orange",
    "number": 
        "orange",
    "boolean": 
        "orange",
    "constant": 
        "orange",

    # Plumbing / Glue
    "keyword": 
        "cyan",
    "label": 
        "cyan",
    "preproc": 
        "cyan",
    "operator": 
        "pink",

    # Background / Neutral
    "primary": 
        "white",
    "embedded": 
        "white",
    "punctuation": 
        "white",
    "punctuation.bracket": 
        "white",
    "punctuation.delimiter": 
        "white",
    "punctuation.list_marker": 
        "white",
    "punctuation.markup": 
        "white",
    "comment": 
        "gray",
    "comment.doc": 
        "light_gray",
    "hint": 
        "gray",

    # Specifics
    "punctuation.special": 
        "pink",
    "string.escape": 
        "pink",
    "string.regex": 
        "pink",
    "string.special": 
        "pink",
    "string.special.symbol": 
        "pink",
    "selector": 
        "google_blue",
    "selector.pseudo": 
        "google_red",
    "namespace": 
        "google_blue",
    "link_text": 
        ("google_blue", "italic", None),
    "link_uri": 
        "orange",
    "title": 
        ("white", None, 700),
    "emphasis": 
        "orange",
    "emphasis.strong": 
        ("orange", None, 700),
    "predictive": 
        ("gray", "italic", None),
    "variant": 
        "google_blue",
    "diff.plus": 
        "google_green",
    "diff.minus": 
        "google_red"
}

def get_syntax_body():
    lines = []
    
    for key, value in SYNTAX_MAPPING.items():
        if isinstance(value, tuple):
            color_name, font_style, font_weight = value
            hex_color = PALETTE[color_name]
            node = {"color": hex_color}
            if font_style is not None:
                node["font_style"] = font_style
            if font_weight is not None:
                node["font_weight"] = font_weight
        else:
            node = {"color": PALETTE[value]}
            
        node_json = json.dumps(node, separators=(', ', ': '))
        lines.append(f'        "{key}": {node_json}')

    return ",\n".join(lines)

def update_zed_settings():
    import os
    settings_path = os.path.expanduser("~/.config/zed/settings.json")
    
    if not os.path.exists(settings_path):
        print(f"Error: Could not find settings.json at {settings_path}")
        return

    with open(settings_path, 'r') as f:
        content = f.read()

    syntax_body = get_syntax_body()
    replacement = f'''"theme_overrides": {{
    "Ayu Dark": {{
      "syntax": {{
{syntax_body}
      }}
    }}
  }}'''

    key_to_find = '"theme_overrides"'
    start_idx = content.find(key_to_find)

    # If the block exists, parse its braces and replace the whole block
    if start_idx != -1:
        brace_start = content.find('{', start_idx)
        if brace_start != -1:
            open_braces = 0
            end_idx = -1
            for i in range(brace_start, len(content)):
                if content[i] == '{':
                    open_braces += 1
                elif content[i] == '}':
                    open_braces -= 1
                    if open_braces == 0:
                        end_idx = i
                        break
            
            if end_idx != -1:
                new_content = content[:start_idx] + replacement + content[end_idx+1:]
                with open(settings_path, 'w') as f:
                    f.write(new_content)
                print("Successfully updated existing 'experimental.theme_overrides' in settings.json!")
                return

    # If the block doesn't exist, inject it right before the final closing brace of settings.json
    last_brace_idx = content.rfind('}')
    if last_brace_idx != -1:
        before_brace = content[:last_brace_idx].strip()
        needs_comma = not before_brace.endswith(',') and not before_brace.endswith('{')
        
        insert_str = ",\n  " + replacement + "\n" if needs_comma else "\n  " + replacement + "\n"
        new_content = content[:last_brace_idx] + insert_str + content[last_brace_idx:]
        
        with open(settings_path, 'w') as f:
            f.write(new_content)
        print("Successfully injected 'experimental.theme_overrides' into settings.json!")
    else:
        print("Error: Could not parse settings.json (no closing brace found).")

if __name__ == "__main__":
    update_zed_settings()
