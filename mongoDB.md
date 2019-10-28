### insert
```
obj = { a : 13, b : 2 }
db.things.insert(obj)
```


### find
```
// find items and omit "_id" field in response
db.things.find({b:2}, {"_id":false})

// Use findOne on the collection users to find one document where the key username is "dwight"
// and retrieve only the key named email.
db.users.findOne({"username":"dwight"},{"email":true, "_id":false})

// retreive documents with a score greater then 2 but less or equal to 5
db.things.find({a: {$gt: 2, $lte: 5}})
```

- also available: gte, lt
- comparing also works on strings. Attention: byte representation of UTF-8 character is used!
- iterating through result list on mongodb shell: type "it" 

```
// find only documents that (don't) contain a specific field
db.things.find({c: {$exists: true}})

// find docs with a property 'a' of type number
// for types see bson spec!
// number = 1
// string = 2
db.things.find({a: {$type: 1}})

// find with like
db.users.find({"name": /asdf/})

// find with regex
db.users.find({"name":{$regex: "q"}})

// combine queries using prefix operators "$and" / "$or", use array as values!
db.things.find({ $or : [ {a: 1}, {d: {$exists: true}} ] })

// How would you find all documents in the scores collection where the score is less than 50 or greater than 90?
db.scores.find({ $or : [ {score: {$lt: 50}}, {score: {$gt: 90}} ] })

// warning: the following query will return _all_ docs with a < 20! 
db.things.find( { a : { $gt : 4 }, a : { $lt : 20 } } );

// second occurrence of "a" will replace the first one! solution: use $and to combine 
db.things.find({ a : { $gt : 4, $lt: 20 } });
db.things.find({ $and: [{ a : { $gt : 4, $lt: 20 } }] });
```


### nested objects and arrays
```
// find is polymorphic and works the same for simple values and arrays:
db.accounts.insert({name: "George", favorites: ["ice cream", "pretzels"]})
db.accounts.insert({name: "Howard", favorites: ["pretzels", "beer"]})
db.accounts.find({favorites: "pretzels"})

// find docs with array that contains all of the given elements (in any order!)
db.accounts.find({favorites: {$all: ["beer", "pretzels"] }})

// find docs with a field having one of the given values
db.accounts.find({name: {$in: ["George", "Max"] }})

// Reaching inside of nested documents using dot notation
db.users.find({ "email.work": "me@example.org" })

// Write a query that finds all products that cost more than 10,000 and that have a rating of 5 or better.
db.catalog.insert({ product : "Super Duper-o-phonic", price : 100000000000, reviews : [  { user : "fred", comment : "Great!" , rating : 5 }, { user : "tom" , comment : "I agree with Fred, somewhat!" , rating : 4 } ]})
db.catalog.find({ "price": {$gt: 10000}, "reviews.rating": {$gte: 5} })
```


### working with cursors
- use cursors to work with query results
```
// the "; null;" at the end prevents the shell to print the result of the previous action!
cur = db.things.find(); null;
cur.limit(2); null;
cur.sort( {a: -1} ); null;
while (cur.hasNext()) printjson(cur.next());

// skipping two elements
cur.skip(2)
```

- when can you change the behavior of a cursor, by applying a sort, skip, or limit to it?
  - can be done at any point before the first document is called and before a length check!

```
// number of elements in cursor
cur.length()

// exercise: Find all exam scores greater than or equal to 65, and sort those scores from lowest to highest.
cur = db.things.find({"type": "exam", "score": {"$gte": 65}}); null;
cur.sort( {"score": 1} ); null;
cur.limit(5);
```


### updates and upserts
```
// performing update without special operators replaces all values but "_id"
db.things.update( {a: 1}, {a: 1337}} )

// add or set new property
db.things.update( {a: 5}, {$set: {f: 50}} )

// increment properties
db.things.update( {a: 5}, {$inc: {d: 1}} )

// remove properties using unset
db.things.update( {a: 5} , {$unset: {f: 1}} )

// use upsert for creating new doc if query does not return existing doc
db.things.update( {...} , {"$set": {...}}, {"$upsert": true} )
db.foo.update( { username : 'bar' }, { '$set' : { 'interests': [ 'cat' , 'dog' ] } } , { "$upsert" : true } );

// by default, update only modifies the first doc returned by the query!
// to update all, use another option
db.things.update( {...} , {"$set": {..-}}, {"multi": true} )

// How would you give every record whose score was less than 70 an extra 20 points?
db.scores.update({"score": {$lt: 70}}, {"$inc": {"score": 20}}, {"multi": true})
```


### remove
```
// removing docs
db.things.remove( {...} ) 

// dropping collections
db.things.drop() 
```


### aggregation functions
```
// GROUP BY
db.products.aggregate([{
  $group: {_
    id:"$manufacturer",
    num_products: {$sum:1}
  }
}])

// compound grouping
db.products.aggregate([{
  $group: {
    _id: {
      "manufacturer": "$manufacturer",
      "category": "$category"
    },
	num_products: {
	  $sum:1
	}
  }
}])

db.products.aggregate([{
  $group: {
    _id: {"maker":"$manufacturer"},
	sum_prices:{$sum:"$price"}
  }
}])

// sum population by state
db.zips.aggregate([{
  $group: {
    _id: "$state",
    "population": {$sum: "$pop"}
  }
}])

// average population per zip code by state
db.smallzips.aggregate([{
  $group: {
    _id: {"state": "$state"},
    "average_pop": {$avg: "$pop"}
  }
}])

// list prod categories per maker
db.products.aggregate([{
  $group: {
    _id: { "maker":"$manufacturer"},
    categories:{$addToSet:"$category"}
  }
}])

// Write an aggregation query that will return the postal codes that cover each city.
db.zips.aggregate([{
  $group: {
    _id: "$city",
    postal_codes:{$addToSet:"$_id"}
  }
}])

// multple grouping is possible!
db.fun.aggregate([{$group:{_id:{a:"$a", b:"$b"}, c:{$max:"$c"}}}, {$group:{_id:"$_id.a", c:{$min:"$c"}}}])

// Write an aggregation query with a single projection stage that will transform the documents in the zips collection
// _id must be handled first
// to keep a field, use "$field":1
db.zips.aggregate([{
  $project: {
    _id: 0,
    "city": {$toLower: "$city"},
	"pop": 1,
	"state": 1,
	"zip": "$_id"
  }
}])

// write an aggregation query with a single match phase that filters for zipcodes with greater than 100,000 people
db.zips.aggregate([{
  $match: {
    "pop": {$gt: 100000}
  }
}])

// sort all cities in state of New York by population
db.zips.aggregate([
    { $match: { state:"NY" } },
    { $group: { _id: "$city", population: {$sum:"$pop"} } },
    { $project: { _id: 0, city: "$_id", population: 1 } },
    { $sort: { population:-1 } }
])

// Write an aggregation query with just a sort stage to sort by (state, city), both ascending. 
db.zips.aggregate([
    { $sort: { "state":1, "city": 1 } }
])

// accessing first or last element of sorted (!) aggregated data via $first and $last:
db.fun.aggregate([
  { $match:{a:0} },
  { $sort:{c:-1} }, 
  { $group:{_id:"$a", c:{$first:"$c"}} }
])
```


### import existing JSON into mongoDB
- file needs to contain a json array!
```
mongoimport --db (db_name) --collection (coll) --file a.json --jsonArray
```


### misc
-  sql examples in mongoDB: https://www.youtube.com/watch?v=ep2gLSR6C0U
