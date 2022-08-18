if grep -rlq "forge-std/console" . --exclude-dir=lib --exclude-dir=node_modules --exclude-dir=scripts; then
  echo "found line that breaks linter rule"
  grep -rl "forge-std/console" . --exclude-dir=lib --exclude-dir=node_modules -exclude-dir=scripts
  exit 1
else
  exit 0
fi
