// Display for 10 seconds + custom avatar
// crate.notify({
//   content: 'Need a 🤚? Hot, sweaty geeks are waiting to chat to you! Click 👇',
//   timeout: 5000,
//   avatar: 'https://avatars2.githubusercontent.com/u/1524686?s=400&v=4'
// })


// This file should _not_ be routinely included, it's here to make tweaking of the widgetbot settings
// faster, since making changes doesn't require restarting mkdocs serve
<script src="https://cdn.jsdelivr.net/npm/@widgetbot/crate@3"></script>

<script>
  const devbutton = new Crate({
  server: '396055506072109067',
  channel: '456689991326760973' // Cookbook channel
  color: '#000',
  indicator: false,
  notifications: true,
  indicator: true,
  timeout: 5000,
  glyph: 'https://avatars2.githubusercontent.com/u/1524686?s=400&v=4'
  })

  devbutton.notify('Hello __world__\n```js\n// This is Sync!\n```')
</script>

