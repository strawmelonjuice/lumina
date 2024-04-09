The `Ephew/Peonies` polling system, or _inter-instance timelining_ might just be one of the hardest and most interesting part of the project.

# Walkthrough
This process is best explained in steps.
## Step 1: The polling request
`[instance A]` makes a HTTP GET request to `[instance B]`'s `/api/ii/poll/{id}/{size}`, where `{id}` is `[instance A]`'s ID (or host/domain name), and `{size}` is the requested amount of history. This is referred to as the polling request.
## Step 2: Identification
The `[instance B]` receives this polling request and checks if the submitted instance ID is on the sync list. 

If not, it'll add the instance to it's waiting list, meaning an administrator should decide if the instance will be allowed manually.
%% 
Earlier, an authentication method was also added, but timelines are in fact supposed to be public, and so, this shouldn't be the default.

In case this'll ever become necessary or preferred again, these are the outlines around that.

 Then send a GET request to `instance A`'s `/api/ii/passcode/{id}/{passcode}`. `{id}` being `instance B`'s ID, and `{passcode}` being a one-time-passcode specific to this polling request.  %%
## Step 3: Response
If listed, `[instance B]`'ll send a JSON array of post-ID's (including comments) (referred to as PID's) appearing recently on the timeline or gaining popular interactions (calculated by a threshold based on time between interactions, that'll all be in [interaction handling](./Interaction%20handling.md)) and falling in the top of whatever the `{size}` is to `[instance A]`.

## Step 4: Organisation
On `[instance A]`, these PID's, prefixed with their hosting instance (`[instance B]`, in this case) are collected into a database, duplicates are eliminated in the process. The [timeline generator](./Timeline%20generation.md) will use this later on to fetch posts and their comments. Comments and posts themselves are **ALWAYS** stored **ONLY** on the instance they were made on. PID's are the only things stored on other instances than their own.