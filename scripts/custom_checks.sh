# This scripts performs custom static checks in CI

# Check if all cairo tests (cairo files and docs) use @external decorator
grep -z '@view.*\nfunc test_.*' $(find . -type f -name '*.cairo' -o -name '*.md')
if [ $? -eq 0 ]; then
    exit 1
fi

exit 0