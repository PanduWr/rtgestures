function result = majorityvote(votes)

hashtable = containers.Map('KeyType', 'char', 'ValueType', 'uint8');

for i = 1:3
    key = cell2mat(votes{i});
    if isKey(hashtable, key)
        hashtable(key) = hashtable(key) + 1;
    else
        hashtable(key) = 1;
    end
end

maxvotes = -1;
maxkey = '';
for k = keys(hashtable)
    key = cell2mat(k);
    if hashtable(key) > maxvotes
        maxvotes = hashtable(key);
        maxkey = key;
    end
end

result  = maxkey;