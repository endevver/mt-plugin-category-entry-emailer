package CategoryEntryEmailer::Plugin;

use strict;
use warnings;

# The blog config template is shown in the Plugin Setttings.
sub blog_config_template {
    my ($plugin, $param) = @_;
    my $app      = MT->instance;
    my $blog_id  = $app->blog->id;
    my $selected = $plugin->get_config_value('email_field', "blog:$blog_id");
    my $options  = '<option value="0">None</option>';

    # Get the category CFs in this blog to build the select picker.
    my @fields = $app->model('field')->load(
        {
            blog_id  => $app->blog->id,
            obj_type => 'category',
        },
        {
            sort      => 'name',
            direction => 'ascend',
        }
    );

    foreach my $field (@fields) {
        $options .= '<option value="' . $field->basename . '" '
            . ( $field->basename eq $selected ? 'selected' : '' )
            . '>' . $field->name . '</option>';
    }

    return <<HTML;
<mtapp:Setting
    id="email_field"
    label="Email Field"
    hint="Select a Category Custom Field where notification email addresses are specified."
    show_hint="1">
    <select
        name="email_field"
        id="email_field">
        $options
    </select>
</mtapp:Setting>
HTML
}

# Fired after submitting an entry through the public submission form.
sub api_post_save_entry {
    my ($cb, $app, $entry, $orig)= @_;
    my $blog_id = $entry->blog_id;
    my $plugin  = $app->component('CategoryEntryEmailer');

    # If $orig has an ID, this is an existing entry that was modified. No need
    # to send a notification; we only want to send one for new entries.
    return if $orig && $orig->id;

    my $cat = $app->model('category')->load(
        undef,
        {
            'join' => $app->model('placement')->join_on(
                'category_id',
                {
                    blog_id    => $blog_id,
                    entry_id   => $entry->id,
                    is_primary => 1,
                }
            )
        }
    )
        # No category assigned? That's ok because we require a category to do
        # the notification.
        or return;

    my $cf_basename = $plugin->get_config_value('email_field', "blog:$blog_id")
        or return;

    my $addresses = $cat->meta('field.'.$cf_basename);

    # No data in the category CF? That's ok, maybe nobody is supposed to be
    # notified about entries created in this category.
    return if ! $addresses;

    # Set params for MT::App::CMS::send_notify()
    $app->mode('send_notify');
    $app->param('send_notify_emails', $addresses);
    $app->param('entry_id', $entry->id);
    $app->param('send_excerpt', 1);

    # Execute MT::App::CMS::send_notify()
    # $app may be an MT::App or it could be MT::App::Community, if the entry
    # is created from a public form.
    my $rc = MT::App::CMS::send_notify($app);
    delete $app->{$_} foreach (qw(redirect redirect_use_meta));

    $app->log({
        level    => $app->model('log')->INFO(),
        category => 'sent',
        class    => 'CategoryEntryEmailer',
        blog_id  => $blog_id,
        message  => 'An email notification was sent to ' . $addresses
            . ' about the creation of the Entry "' . $entry->title . '" (ID '
            . $entry->id . ').',
    });

    $rc;
}

1;

__END__
