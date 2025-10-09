If we are going to make directories, we want to do this at the very start for anything eligible. If there are temp directories that should only be created in that moment, then you DON'T need to follow that rule.

An example of something you CANNOT create at the start:
```
mkdir -p /tmp/jack2 && cd /tmp/jack2
```