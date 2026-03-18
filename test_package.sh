#!/bin/bash

# Flutter Lens Package Testing Script
# Run this before publishing to pub.dev

set -e  # Exit on error

echo "🧪 Testing Flutter Lens Package..."
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 1. Run analysis
echo "📊 Step 1/6: Running Flutter analyze..."
if flutter analyze; then
    echo -e "${GREEN}✅ Analysis passed${NC}"
else
    echo -e "${RED}❌ Analysis failed${NC}"
    exit 1
fi
echo ""

# 2. Run tests
echo "🧪 Step 2/6: Running unit tests..."
if flutter test; then
    echo -e "${GREEN}✅ All tests passed${NC}"
else
    echo -e "${RED}❌ Tests failed${NC}"
    exit 1
fi
echo ""

# 3. Check package structure
echo "📦 Step 3/6: Validating package structure..."
if flutter pub publish --dry-run > /dev/null 2>&1; then
    warnings=$(flutter pub publish --dry-run 2>&1 | grep -i "warning" | wc -l)
    if [ "$warnings" -eq 0 ]; then
        echo -e "${GREEN}✅ Package structure valid (0 warnings)${NC}"
    else
        echo -e "${YELLOW}⚠️  Package has warnings${NC}"
        flutter pub publish --dry-run
    fi
else
    echo -e "${RED}❌ Package validation failed${NC}"
    exit 1
fi
echo ""

# 4. Check example app
echo "🎯 Step 4/6: Checking example app..."
cd example
if flutter pub get > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Example dependencies resolved${NC}"
else
    echo -e "${RED}❌ Example pub get failed${NC}"
    exit 1
fi
cd ..
echo ""

# 5. Check for required files
echo "📄 Step 5/6: Checking required files..."
required_files=("README.md" "LICENSE" "CHANGELOG.md" "pubspec.yaml")
for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        echo -e "${GREEN}✅ $file exists${NC}"
    else
        echo -e "${RED}❌ $file missing${NC}"
        exit 1
    fi
done
echo ""

# 6. Summary
echo "📋 Step 6/6: Package summary..."
echo ""
echo "Package: flutter_lens"
echo "Version: $(grep '^version:' pubspec.yaml | cut -d' ' -f2)"
echo "Files: $(find lib -name '*.dart' | wc -l | xargs) Dart files"
echo "Tests: $(find test -name '*.dart' | wc -l | xargs) test files"
echo "Example: $([ -d example ] && echo 'Yes' || echo 'No')"
echo ""

echo -e "${GREEN}✅ All checks passed! Package is ready to publish!${NC}"
echo ""
echo "Next steps:"
echo "  1. Update GitHub URLs in pubspec.yaml"
echo "  2. Test example app: cd example && flutter run"
echo "  3. Create GitHub repository and push"
echo "  4. Publish: flutter pub publish"
echo ""
