#!/usr/bin/env python3
"""PRD Generator - Compiles brainstorming session data into a structured PRD."""

import json
import sys
from datetime import date
from pathlib import Path


def load_session_data(filepath: str) -> dict:
    with open(filepath, 'r') as f:
        return json.load(f)


def generate_mermaid_diagram(data: dict) -> str:
    components = data.get('system_components', [])
    
    lines = ['flowchart TD', '    subgraph "System Architecture"']
    
    for i, component in enumerate(components):
        comp_id = f"c{i+1}"
        comp_name = component.get('name', 'Component')
        comp_type = component.get('type', 'service').lower()
        
        shape = {
            'database': '[([Database])]',
            'api': '[(API)]',
            'frontend': '[(Frontend)]',
            'backend': '[(Backend)]',
            'queue': '[{Message Queue}]',
            'cache': '[(Cache)]',
        }.get(comp_type, f'[{comp_name}]')
        
        lines.append(f'    {comp_id}{shape}')
    
    lines.append('    end')
    lines.append('')
    lines.append('    subgraph "External Services"')
    
    external_services = data.get('external_services', [])
    for i, external in enumerate(external_services):
        ext_id = f"ext{i+1}"
        ext_name = external.get('name', 'Service')
        lines.append(f'    {ext_id}[({ext_name})]')
    
    lines.append('    end')
    lines.append('')
    lines.append('    %% Data Flows')
    
    flows = data.get('data_flows', [])
    for flow in flows:
        source = flow.get('source', '')
        target = flow.get('target', '')
        description = flow.get('description', 'data')
        
        src_id = None
        tgt_id = None
        
        for i, comp in enumerate(components):
            if comp.get('name', '').lower() in source.lower():
                src_id = f"c{i+1}"
                break
        
        for i, ext in enumerate(external_services):
            if ext.get('name', '').lower() in target.lower():
                tgt_id = f"ext{i+1}"
                break
        
        if not src_id:
            for i, comp in enumerate(components):
                if target.lower() in comp.get('name', '').lower():
                    src_id = f"c{i+1}"
        
        if src_id and tgt_id:
            lines.append(f'    {src_id} -->|{description}| {tgt_id}')
        elif src_id:
            lines.append(f'    {src_id} -->|{description}| {target}')
    
    return '\n'.join(lines)


def generate_prd(data: dict) -> str:
    sections = []
    
    sections.append('---')
    sections.append(f"product: {data.get('product_name', 'Product')}")
    sections.append(f"version: {data.get('version', '1.0.0')}")
    sections.append(f"date: {data.get('date', date.today().isoformat())}")
    sections.append(f"status: {data.get('status', 'Draft')}")
    if data.get('authors'):
        sections.append(f"authors: {', '.join(data['authors'])}")
    sections.append('---')
    sections.append('')
    
    sections.append(f"# {data.get('product_name', 'Product')} Requirements Document")
    sections.append('')
    
    sections.append("## Overview")
    sections.append(f"**Vision**: {data.get('vision', '[Define product purpose]')}")
    sections.append('')
    sections.append('**Goals**:')
    for goal in data.get('goals', []):
        sections.append(f"- {goal}")
    sections.append('')
    
    sections.append('**Success Metrics**:')
    for metric in data.get('success_metrics', []):
        target = metric.get('target', 'N/A')
        sections.append(f"- {metric.get('name', 'Metric')}: {target}")
    sections.append('')
    
    sections.append("## User Personas")
    for persona in data.get('user_personas', []):
        sections.append(f"### {persona.get('name', 'Persona')}")
        sections.append(f"- **Role**: {persona.get('role', 'Unknown')}")
        sections.append(f"- **Needs**: {persona.get('needs', 'N/A')}")
        sections.append(f"- **Pain points**: {persona.get('pain_points', 'N/A')}")
        sections.append('')
    
    sections.append("## Feature Specifications")
    for feature in data.get('features', []):
        sections.append(f"### {feature.get('name', 'Feature')}")
        sections.append(f"- **Priority**: {feature.get('priority', 'Medium')}")
        sections.append(f"- **Description**: {feature.get('description', 'N/A')}")
        sections.append('')
        sections.append('  **Acceptance Criteria**:')
        for criterion in feature.get('acceptance_criteria', []):
            sections.append(f"  1. {criterion}")
        sections.append('')
    
    sections.append("## System Architecture")
    sections.append(f"```mermaid\n{generate_mermaid_diagram(data)}\n```")
    sections.append('')
    
    if data.get('system_components'):
        sections.append("### Components")
        for component in data.get('system_components', []):
            sections.append(f"- **{component.get('name', 'Component')}** ({component.get('type', 'service')}): {component.get('description', 'N/A')}")
        sections.append('')
    
    sections.append("## Non-functional Requirements")
    nfr = data.get('non_functional_requirements', {})
    if nfr:
        if nfr.get('performance'):
            sections.append(f"- **Performance**: {nfr['performance']}")
        if nfr.get('security'):
            sections.append(f"- **Security**: {nfr['security']}")
        if nfr.get('scalability'):
            sections.append(f"- **Scalability**: {nfr['scalability']}")
        if nfr.get('availability'):
            sections.append(f"- **Availability**: {nfr['availability']}")
    else:
        sections.append("- *[Define non-functional requirements]*")
    sections.append('')
    
    sections.append("## Risks & Dependencies")
    for item in data.get('risks_and_dependencies', []):
        is_risk = item.get('type', '') == 'risk'
        prefix = '[ Risk ]' if is_risk else '[ Dependency ]'
        description = item.get('description', '')
        validated = '' if item.get('validated', False) else ' `TODO: Validate`'
        sections.append(f"- {prefix} {description}{validated}")
    sections.append('')
    
    if data.get('assumptions'):
        sections.append("## Assumptions")
        for assumption in data.get('assumptions', []):
            sections.append(f"- {assumption}")
        sections.append('')
    
    return '\n'.join(sections)


def main():
    """Main entry point."""
    if len(sys.argv) != 3:
        print("Usage: python3 generate_prd.py <input.json> <output.md>", file=sys.stderr)
        sys.exit(1)
    
    input_file = sys.argv[1]
    output_file = sys.argv[2]
    
    try:
        data = load_session_data(input_file)
    except FileNotFoundError:
        print(f"Error: Input file '{input_file}' not found", file=sys.stderr)
        sys.exit(1)
    except json.JSONDecodeError as e:
        print(f"Error: Invalid JSON in input file: {e}", file=sys.stderr)
        sys.exit(1)
    
    prd_content = generate_prd(data)
    
    output_path = Path(output_file)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    
    with open(output_file, 'w') as f:
        f.write(prd_content)
    
    print(f"PRD generated successfully: {output_file}")


if __name__ == '__main__':
    main()
