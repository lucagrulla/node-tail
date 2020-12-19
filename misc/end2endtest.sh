rm -rf test.txt && touch test.txt
echo "empty test file created."
limit=$1 || 200000
echo "running test with $limit lines"
ruby producer.rb $limit &
node test.js $limit

wait
rm -rf test.txt
# time -p sh -c 'ruby producer.rb $limit &;node test.js $limit'