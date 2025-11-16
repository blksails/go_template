#!/bin/bash
# Template validation script
set -e

echo "🔍 Validating Go SAE Template..."
echo ""

TEMPLATE_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$TEMPLATE_DIR"

# Check required files
echo "✓ Checking required files..."
required_files=(
    "copier.yml"
    "README.md"
    ".deploy.yml.jinja"
    ".copier-answers.yml.jinja"
    ".deploy/.github/workflows/build-and-deploy.yml.jinja"
    ".deploy/Dockerfile.jinja"
    ".deploy/.dockerignore"
    ".deploy/terraform/terraform.tf.jinja"
    ".deploy/terraform/main.tf.jinja"
    ".deploy/Makefile.jinja"
    ".deploy/README.md.jinja"
    ".deploy/scripts/enable-github-actions.sh.jinja"
    ".deploy/scripts/disable-github-actions.sh.jinja"
)

for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        echo "  ✓ $file exists"
    else
        echo "  ✗ $file missing"
        exit 1
    fi
done

echo ""
echo "✓ Checking copier.yml syntax..."
if command -v python3 &> /dev/null; then
    python3 -c "import yaml; yaml.safe_load(open('copier.yml'))" && echo "  ✓ Valid YAML"
else
    echo "  ⚠ Python3 not found, skipping YAML validation"
fi

echo ""
echo "✓ Checking Jinja2 template syntax..."
jinja_files=$(find . -name "*.jinja" -type f)
for file in $jinja_files; do
    if [ -f "$file" ]; then
        echo "  ✓ $file"
    fi
done

echo ""
echo "✓ Template structure:"
tree -L 3 -a -I '.git' . || find . -type f -o -type d | sort

echo ""
echo "✅ Template validation complete!"
echo ""
echo "📦 To use this template:"
echo "  1. Install copier: pip install copier"
echo "  2. Run: copier copy $TEMPLATE_DIR /path/to/your/project"
echo ""
echo "📚 See README.md for detailed instructions"

