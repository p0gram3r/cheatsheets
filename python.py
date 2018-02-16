# Null of Python
None


# exception handling
try:
   print("Hello")
   print(1 / 0)
except ZeroDivisionError:
   print("Divided by zero")
finally:
   print("This code will run no matter what")


# open and auto-close files
with open("python.py") as f:
   print(f.read())


# dictionaries
pairs = {1: "apple",
  "orange": [2, 3, 4],
  True: False,
  None: "True",
}
print(1 in pairs)
print(4 not in pairs)
print(pairs.get(1))
print(pairs.get("orange"))
print(pairs.get(12345, "not in dictionary"))


# tupels
# - similar to lists, but immutable
words = ("spam", "eggs", "sausages",)
print(words[0])
# - can be created by just separating the values with commas.
my_tuple = "one", "two", "three"


# slicing lists and tupels
# - use a range to fetch a new list containing only value of those indices
# - first index is inclusive, second exclusive
squares = [0, 1, 4, 9, 16, 25, 36, 49, 64, 81]
print(squares[2:6])
# - if one index is blank, first or last index is filled resp.
print(squares[7:])
print(squares[:7])
# - third number is step
print(squares[::2])
print(squares[2:8:3])


# a list comprehension
cubes = [i**3 for i in range(5)]
print(cubes)
# - also works with additional condition
evens=[i**2 for i in range(10) if i**2 % 2 == 0]
print(evens)
