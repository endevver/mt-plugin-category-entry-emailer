# Category-Based Entry Creation Email Notifier

This is a plugin for Movable Type that helps keep moderators and administrators aware of new content by email them about the creation of new entries.

Note that this plugin currently only works for entries created through a Community.Pack public submission form.

A category-level Custom Field is needed -- you probably want to create a text or textarea type field -- where email addresses can be specified. Email addresses should be on separate lines or separted by commas.

At the blog level Plugin Settings, be sure to choose which Custom Field you've created for email addresses.

When an entry is created through the public submission form, this plugin will check for any email addresses in the specified field, and send email through MT's standard `send_notify` mechanism, and will also note when an email has been sent and to whom.

# License

This plugin is licensed under the same terms as Perl itself.

# Copyright

Copyright 2016, [Endevver LLC](http://endevver.com). All rights reserved.
