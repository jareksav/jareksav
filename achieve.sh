#!/bin/bash
# Użycie: bash achieve.sh TWOJ_TOKEN_GITHUB
# Token musi mieć scope: repo

TOKEN=$1
REPO="jareksav/jareksav"
API="https://api.github.com"
DIR="/home/vis_animi/Projects/jareksav"

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

if [ -z "$TOKEN" ]; then
  echo -e "${RED}Użycie: bash achieve.sh TWOJ_TOKEN${NC}"
  exit 1
fi

echo -e "${BLUE}Sprawdzam token...${NC}"
ME=$(curl -s -H "Authorization: token $TOKEN" "$API/user" | python3 -c "import sys,json; print(json.load(sys.stdin).get('login','BŁĄD'))")
if [ "$ME" != "jareksav" ]; then
  echo -e "${RED}Token nie należy do konta jareksav (zalogowany jako: $ME). Sprawdź token.${NC}"
  exit 1
fi
echo -e "${GREEN}Token OK — zalogowany jako $ME${NC}"

cd $DIR

merge_pr() {
  local branch=$1
  local title=$2
  local action=$3

  echo -e "\n${BLUE}>>> Branch: $branch${NC}"

  git checkout main -q
  git pull origin main -q
  git checkout -b "$branch" -q

  eval "$action"

  git add -A
  git commit -m "$title" -q

  git push origin "$branch" -q 2>&1

  PR=$(curl -s -X POST \
    -H "Authorization: token $TOKEN" \
    -H "Content-Type: application/json" \
    "$API/repos/$REPO/pulls" \
    -d "{\"title\":\"$title\",\"head\":\"$branch\",\"base\":\"main\",\"body\":\"\"}" \
    | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('number','ERR'))")

  echo -e "  PR #$PR otwarty"

  RESULT=$(curl -s -X PUT \
    -H "Authorization: token $TOKEN" \
    -H "Content-Type: application/json" \
    "$API/repos/$REPO/pulls/$PR/merge" \
    -d '{"merge_method":"squash"}' \
    | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('message','ERR'))")

  echo -e "  ${GREEN}Zmergowany: $RESULT${NC}"

  git checkout main -q
  git pull origin main -q
  git branch -D "$branch" -q 2>/dev/null
}

quickdraw() {
  echo -e "\n${BLUE}>>> Quickdraw: tworzę i zamykam issue w <5 minut${NC}"

  ISSUE=$(curl -s -X POST \
    -H "Authorization: token $TOKEN" \
    -H "Content-Type: application/json" \
    "$API/repos/$REPO/issues" \
    -d '{"title":"chore: initial setup check","body":"Closing immediately."}' \
    | python3 -c "import sys,json; print(json.load(sys.stdin).get('number','ERR'))")

  echo -e "  Issue #$ISSUE otwarte"

  curl -s -X PATCH \
    -H "Authorization: token $TOKEN" \
    -H "Content-Type: application/json" \
    "$API/repos/$REPO/issues/$ISSUE" \
    -d '{"state":"closed"}' > /dev/null

  echo -e "  ${GREEN}Issue zamknięte — Quickdraw odblokowany${NC}"
}

# ── QUICKDRAW ────────────────────────────────────────────────────────────────
quickdraw

# ── 16 PR-ów → Pull Shark Silver + YOLO ─────────────────────────────────────

merge_pr "add-gitignore" "Add .gitignore" \
  'cat > .gitignore << EOF
*.pyc
__pycache__/
.env
.DS_Store
node_modules/
dist/
*.log
EOF'

merge_pr "add-license" "Add MIT LICENSE" \
  'cat > LICENSE << EOF
MIT License

Copyright (c) 2026 Jarosław Sawczenko

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
EOF'

merge_pr "add-tailwind-badge" "Update tech stack: add Tailwind and Docker" \
  'sed -i "s|<img src=\"https://img.shields.io/badge/Git|<img src=\"https://img.shields.io/badge/Tailwind_CSS-06B6D4?style=flat-square\&logo=tailwindcss\&logoColor=white\" />\n  <img src=\"https://img.shields.io/badge/Docker-2496ED?style=flat-square\&logo=docker\&logoColor=white\" />\n  <img src=\"https://img.shields.io/badge/Git|" README.md'

merge_pr "update-about-section" "Improve About me description" \
  'sed -i "s/I have real-world experience taking projects all the way from Figma design to production deployment./I have real-world experience taking projects all the way from Figma design to production deployment. I care about clean code, solid architecture and shipping products that actually work./" README.md'

merge_pr "add-open-to-work" "Add open to work badge" \
  'sed -i "s|<img src=\"https://komarev.com|<img src=\"https://img.shields.io/badge/Open%20to%20work-238636?style=flat-square\&logo=github\&logoColor=white\" />\n  \&nbsp;\n  <img src=\"https://komarev.com|" README.md'

merge_pr "update-lumen-features" "Expand Lumen feature list" \
  'sed -i "s|- Production-ready config via \`python-dotenv\`|- Production-ready config via \`python-dotenv\`\n- SQLite (dev) \/ PostgreSQL (prod) database support/" README.md'

merge_pr "update-legalline-desc" "Improve LegalLine project description" \
  'sed -i "s/a full architectural overhaul, not just a restyle./a full architectural overhaul, not just a restyle. Performance, SEO and maintainability all significantly improved./" README.md'

merge_pr "update-svgroup-desc" "Improve SV Group project description" \
  'sed -i "s/A complete company website delivered end-to-end - designed, developed and deployed entirely by me./A complete company website for a construction company, delivered end-to-end - designed, developed and deployed entirely by me. Responsive, fast and production-ready./" README.md'

merge_pr "add-currently-building" "Add Currently building section" \
  'sed -i "/^---$/{ /^---$/!b; N; /^---\n## About me/i ---\n\n## Currently building\n\n![Working on](https://img.shields.io/badge/Lumen_v2-in_progress-1f6feb?style=flat-square\&logo=github\&logoColor=white)\n" }
# Simpler approach
python3 -c "
content = open(\"README.md\").read()
insert = \"\"\"---\n\n## Currently building\n\n![Lumen v2](https://img.shields.io/badge/Lumen_v2-in_progress-1f6feb?style=flat-square&logo=github&logoColor=white)\n\n\"\"\"
content = content.replace(\"---\n\n## About me\", insert + \"## About me\", 1)
open(\"README.md\", \"w\").write(content)
"'

merge_pr "add-connect-section" "Add Connect section with social links" \
  'python3 -c "
content = open(\"README.md\").read()
section = \"\"\"\n---\n\n## Connect\n\n<p>\n  <a href=\"mailto:jareksawchenko@gmail.com\"><img src=\"https://img.shields.io/badge/Email-D14836?style=flat-square&logo=gmail&logoColor=white\" /></a>\n  &nbsp;\n  <a href=\"https://svgroup.site\"><img src=\"https://img.shields.io/badge/svgroup.site-000000?style=flat-square&logo=vercel&logoColor=white\" /></a>\n  &nbsp;\n  <a href=\"https://legalline.pl\"><img src=\"https://img.shields.io/badge/legalline.pl-000000?style=flat-square&logo=vercel&logoColor=white\" /></a>\n</p>\n\n\"\"\"
content = content.replace(\"## GitHub stats\", section.lstrip() + \"## GitHub stats\", 1)
open(\"README.md\", \"w\").write(content)
"'

merge_pr "improve-trophy-row" "Improve trophy display settings" \
  'sed -i "s/column=7/column=8\&rank=SECRET,SSS,SS,S,AAA,AA,A,B,C/" README.md'

merge_pr "add-html-css-badge" "Add HTML and CSS to tech stack" \
  'sed -i "s|<img src=\"https://img.shields.io/badge/Tailwind|<img src=\"https://img.shields.io/badge/HTML5-E34F26?style=flat-square\&logo=html5\&logoColor=white\" />\n  <img src=\"https://img.shields.io/badge/CSS3-1572B6?style=flat-square\&logo=css3\&logoColor=white\" />\n  <img src=\"https://img.shields.io/badge/Tailwind|" README.md'

merge_pr "update-figma-desc" "Enhance Figma portfolio description" \
  'sed -i "s/On my second account \[@JaroslawSawczenko\]/Each project covers full UX flow — from wireframe logic to visual system. On my second account [@JaroslawSawczenko]/" README.md'

merge_pr "improve-stats-layout" "Improve stats section spacing" \
  'sed -i "s/## GitHub stats/## GitHub stats\n/" README.md'

merge_pr "add-rest-api-badge" "Add REST API badge to tech stack" \
  'sed -i "s|<img src=\"https://img.shields.io/badge/Git|<img src=\"https://img.shields.io/badge/REST_API-005571?style=flat-square\&logo=fastapi\&logoColor=white\" />\n  <img src=\"https://img.shields.io/badge/Git|" README.md'

merge_pr "final-polish" "Final README polish and consistency pass" \
  'python3 -c "
content = open(\"README.md\").read()
# Clean up any double blank lines
import re
content = re.sub(r\"\n{3,}\", \"\n\n\", content)
open(\"README.md\", \"w\").write(content)
"'

echo -e "\n${GREEN}════════════════════════════════════════${NC}"
echo -e "${GREEN} GOTOWE! Achievementy odblokowane:${NC}"
echo -e "${GREEN}  ✓ Quickdraw${NC}"
echo -e "${GREEN}  ✓ YOLO (pierwszy PR bez review)${NC}"
echo -e "${GREEN}  ✓ Pull Shark Bronze (2 PR)${NC}"
echo -e "${GREEN}  ✓ Pull Shark Silver (16 PR)${NC}"
echo -e "${GREEN}════════════════════════════════════════${NC}"
