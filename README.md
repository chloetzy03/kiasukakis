# Kiasu Kakis

A queue companion for iPhone. See how long the wait is at food places in Singapore, join the queue from your phone, and walk over when it is almost your turn.

**Website:** https://chloetzy03.github.io/kiasukakis/

## What it does
- Map of food places (hawker, restaurant, café, dessert, bar) with colour-coded wait times
- Queue-first bottom sheet, place details with Google rating, hours and photo
- Join a virtual queue (max 2 at a time) and track your ticket
- Save places and filter them by category
- VoiceOver, Dynamic Type and Reduce Motion support

> The places are real. The queues are **simulated** for this demo, because Singapore has no public queue data.

## Tech
Swift, UIKit (code only, no storyboards), VIPER, MapKit, Core Location, Google Places API, Core Animation. iOS 17+.

## Run it
1. Open `kiasu kakis.xcodeproj` in Xcode.
2. Copy `Secrets.example.xcconfig` to `Secrets.xcconfig` and add your own Google Places API key (the app still works without one, with Apple data only).
3. Pick an iPhone simulator and press Run.
