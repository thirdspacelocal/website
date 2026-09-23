---
title: "Give Back Mondays"
layout: give-back
heading: "$2 a pint, every Monday, to a local cause."
eyebrow: "Give Back Mondays"
subtitle: "One local nonprofit takes the night. $2 from every pint we pour that day goes to them, and we provide a table by the door for their materials and donations."
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
    body: "We list your night on our events calendar, post it to our social media, and include it in the calendar feeds people subscribe to. You also get a page here you can send to your own list."
  - title: "$2 from every pint"
    body: "Every draft pint we pour that day, from open to close. The more of your supporters who come, the more it raises."
  - title: "A table by the door"
    body: "We provide a table by the door for your banner, sign-up sheets, or a donation jar. Staff it yourself, drop your materials off, or skip the table. You keep everything you collect there."

# Rendered as a plain list under "What we ask". Kept to four because every one
# of them is a real condition someone has agreed to enforce. Do not add a fifth
# unless it is also true.
ask:
  - "Promote the night to your supporters. The pint money only adds up if they come."
  - "Send us your logo and a line about what the money funds, three weeks ahead."
  - "Be a 501(c)(3). We check that you're registered to solicit in Colorado. If you're not sure, ask us and we'll walk you through it."
---

Every Monday belongs to one local nonprofit. It could be yours.

$2 from every draft pint we pour that day goes to your organization. You bring
your supporters in to drink, and we provide a table by the door for sign-up
sheets, a donation jar, or whatever else you're asking people for.

We book one local organization per night. School booster clubs and PTOs, food
banks, animal rescues, youth sports, arts groups, any local group doing useful
work nearby. Monday is the standing slot. If your people can't do a Monday, say
so on the form and we'll look for another night.
