# constellation
*no promises, but its better than nothing*

## accolades
`` we didn't expect this to be useful but by golly `` - John, IT manager of 45 years

`` whoever designed this garbage should be shot into the sun, why are you just deleting user's files `` -- anonymous reddit user

`` our team tried to deploy this software and it worked, but it also gave us a sense of fear we could not understand `` -- man currently screaming from his eyes

`` it just works `` - todd howard, upon cleaning up his computer of all his little lies

---
# intro 

this is a suite of powershell scripts packed together into a fun package we call constellation. its meant to make some parts of my life easier, hopefully it does for you as well.

# modules

1. OSTCleanup - checks profiles for inactive (older than x days) users, finds their OST files, and nukes them from orbit. outlook is right to be killed. but so should exchange. and i cannot kill a god as hard as i try. only decomission its on prem servers.
2. IPScanner - ugh i can't believe i even have to make a tool like this but there are no functional IP scanner tools that are free anymore that offer actual functionality, hopefully this is the start of much more. its a quick and dirty thrown together scanner but here we are. it should detect the active adapter, but there are argments to do otherwise.
3. PartitionFinder - now this one, sorta redundant, i know there are SO many tools that do this, but it also lets you drill down a drive and find the largest folders which might help in figuring out drive space for a tech who has cli access and needs to clear some data rqrq yk?

# notes

1. you run the software, each module does what it says on the tin.
2. dont be stupid, there are ways to shoot yourself in the foot. don't do that. most commands that are destructive have a ``--dry-run`` where i find appropiate.
3. THERE ARE THINGS THAT WILL DELETE FILES AND THEY WILL LIKELY NOT BE RECOVERABLE
4. okay now that nobody is reading this, hi
5. i won't make any additions that don't seem useful. this is meant to be a curation.
