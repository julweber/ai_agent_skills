# How to use the ralph loop

```bash

local_git_repo_path="/path/to/ralph_repo"

# From your project root
mkdir -p scripts/ralph
cp $local_git_repo_path/ralph/opencode-ralph.sh scripts/ralph/opencode-ralph.sh

# Copy the prompt template
cp $local_git_repo_path/ralph/prompt.md scripts/ralph/prompt.md

chmod +x scripts/ralph/opencode-ralph.sh

# Copy the skills to the project
mkdir -p .opencode/skills
cp -r $local_git_repo_path/skills/ralph-prd-converter .opencode/skills/
cp -r $local_git_repo_path/skills/ralph-prd-generator .opencode/skills/

# show the file trees (optional)
tree scripts
tree .opencode
```

# How to start
```
# in your project root ->

# initialize it as a git repo (if not done already)
git init

# add ralph configuration (if not done already)
git add .opencode/skills/ralph*
git add scripts/ralph
git status
git commit -m "ralph-loop installed"

# start opencode
opencode .

# Start the `ralph-prd-generator` skill
# #> /ralph-prd-generator

# walk through the questions

# review the created PRD file !!!

# start a new session in opencode
# #> /new

# convert the generated prd into the json format using the skill
# #> /ralph-prd-converter PRD path: INSERT_PATH_TO_GENERATED_PRD

# check generated files
ls -lacht tasks
less tasks/prd.json

# start the ralph-loop
./scripts/ralph/opencode-ralph.sh
```