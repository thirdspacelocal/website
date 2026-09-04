---
title: "Give Back Mondays"
layout: give-back
heading: "$2 a pint, every Monday, to a local cause."
eyebrow: "Give Back Mondays"
subtitle: "One local nonprofit takes the night. $2 from every pint we pour that day goes to them, and there's a table by the door if they want one."
description: "Give Back Mondays at Gravity Brewing in Louisville, Colorado. A fundraiser night for local nonprofits, schools and booster clubs in Boulder County: $2 from every draft pint we pour that day goes to your organization. Apply for a night."
# The first Give Back night. Before this date the page sells the launch and
# pushes applications; on and after it, that framing disappears on its own.
# Kit rebuilds the site nightly (the "Publish the events website overnight"
# job, 2am), so the switch happens within a day of the date without anyone
# editing anything. Quoted so Hugo hands the layout a string to parse in the
# venue's zone rather than a UTC-midnight time.Time.
launchDate: "2026-10-05"
heroImage: images/tr-crowd.jpg
splitImage: images/band-beer.jpg
splitAlt: "A full night in the taproom at Gravity Brewing"
visit: true
# HTML only, same reason as private-events: this is a section purely so the
# thank-you page can live at /give-back/thanks/, and the default section RSS
# would advertise a feed whose only item is that thank-you page.
outputs: ["HTML"]

# Three cards, written for the person at the charity deciding whether this is
# worth their time. The customer-facing version of the offer is the hero line
# above, and it is deliberately the same number said the same way. Colorado
# requires the per-pint figure in every advertisement, so "$2 from every pint"
# is the one phrase that has to survive editing anywhere it appears.
what:
  - title: "A Monday with your name on it"
    body: "Your night goes on our calendar, out to our social media, and into the calendar feeds anyone can subscribe to. You also get a page here you can send to your own list."
  - title: "$2 from every pint"
    body: "Every draft pint we pour that day, from open to close. The more of your people turn up, the bigger it gets."
  - title: "A table, if you want one"
    body: "There's room by the door for a banner, a sign-up sheet, a donation jar, whatever you want to put out. Come and work it, drop it off, or skip it altogether. Anything you collect there is yours and we take none of it."

# Rendered as a plain list under "What we ask". Kept to four because every one
# of them is a real condition someone has agreed to enforce. Do not add a fifth
# unless it is also true.
ask:
  - "Tell your people. The pint money only gets interesting when they turn up."
  - "Send us your logo and a line about what the money funds, three weeks ahead."
  - "Be a 501(c)(3). We check that you're registered to solicit in Colorado, and we can help you work it out if you're not sure."
---

Every Monday belongs to one local nonprofit. It could be yours.

We put $2 from every draft pint we pour that day into your pot. You tell your
people to come and drink, and if you want a table by the door for anything else
you're asking for, it's there.

We book one local organization per night. School booster clubs and PTOs, food
banks, animal rescues, youth sports, arts groups, anything doing something
useful near here. Monday is the standing slot. If your people can't do a
Monday, say so on the form and we'll see what we can work out.
