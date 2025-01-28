


-----------------------------------------------------------
| Guild 1 - Color                                        ||
| Guild 2 - Color                                        ||
| Guild 3 - Color                                        ||
-----------------------------------------------------------
|                                         ||Player1-realm||
|                                         ||Player2-realm||
|                                         ||Player3-realm||
|                                         ||             ||
|                                         ||             ||
|[M][Player1]Hi All, how is everyone?     ||             ||
|[A][Player2]Doing good and you?          ||             ||
-----------------------------------------------------------
|[M][Player]|Glad everyone is doing great!|Send button|   |
-----------------------------------------------------------

ChatPane page layout
1. Top frame is a scrollbox that shows the guilds in the text color the messages from players in them will be in.
1.1. List of guilds come from the isGuildFederatedMember function and saved in a shareddata.setup[key].data.chat.[guild].color table
2. Center left frame is the chat messages scrollbox
2.1. Listener needed to catch the incoming messages from the chatchannel channel to display here
3. Center right is the list of players joined into the chatchannel channel scrollbox.  Player names need to follow class color.
4. Show if this is the main or alt, then player, then an Editbox field to send messages, and a send button at the end
4.2. Before the editbox should show the [M] [Player1]
4.3. M = Main or A = Alt.. M color is Blue and A is Green...  If playername-realm matches the maincharater in the characterinfo table then Main else Alt.
4.4. Player name needs to be the class color from characterinfo table'd class
4.5. The message text needs to reflect the guild color from shareddata.setup[key].data.chat.color.[guild].colorcode


["setup"] = {
["No Rest For The Wicked-Eonar"] = {
["deleted"] = false,
["tableType"] = "setup",
["lastUpdated"] = "20241229145519",
["guildName"] = "No Rest For The Wicked-Eonar",
["id"] = "No Rest For The Wicked-Eonar",
["data"] = {
["guilds"] = {
{
["name"] = "No Rest For The Wicked-Eonar",
},
{
["name"] = "No Reset For The Wicked-Eonar",
},
{
["name"] = "No Rest For The Wicked-Alleria",
},
{
["name"] = "No Reset For The Wicked-Alleria",
},
},
["chat"] = {
["color"] = {
["No Rest For The Wicked-Alleria"] = {
["colorcode"] = "0025ff",
},
["No Reset For The Wicked-Alleria"] = {
["colorcode"] = "ffb0db",
},
["No Reset For The Wicked-Eonar"] = {
["colorcode"] = "b97607",
},
["No Rest For The Wicked-Eonar"] = {
["colorcode"] = "25ff36",
},
},
["chatchannel"] = "guildhelpernrftw",
["bgcolor"] = "7b7c79",
["channelpassword"] = "9876543210",
},
},
},
},
