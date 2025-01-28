


1. GuildChat.lua to work with chatpane.lua to replicate\sync federated guild chats without changing any of the code.
2. We need a way to make sure messsages are not duplicated in the guild or guildhelper chats.
2.1. Maybe use a identifier code like [g1.az] for guild 1 for the first guild in the rows and a two digit alpha count since we only keep 300 chat messages max
2.2. Can wow LUA count with alpha characters using the alphabet? so A to Z up to 26x26=676 messages for each guild in two characters
2.3. This way once a messages it replicated to all let's say four guilds they do not get duplicated multiple times in the same guildhelper or guild chat windows.
3. 






        <------>Guild 1's chat
        |
Addon1<->
        |
        <------>Guidhelper chat
        |
Addon2<->
        |
        <------>Guild 2's chat