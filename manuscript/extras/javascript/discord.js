new Crate({
  server: '396055506072109067',
  channel: '396055506663374849',
  color: 'black',
  indicator: false,
  notifications: true
})

// Display for 2 seconds + custom avatar
crate.notify({
  content: 'Need a 🤚? Hot, sweaty geeks are waiting to chat to you! Click 👇',
  timeout: 2000,
  avatar: 'https://avatars2.githubusercontent.com/u/1524686?s=400&v=4'
})
