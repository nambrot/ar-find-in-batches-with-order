# ar-find-in-batches-with-order

Allows you to use find_each and find_each_in_batches with custom ordering.

This is useful if your domain knowledge allows you to make assumptions about the order of your records. In the vanilla find_each/find_each_in_batches implementation, Rails disables custom ordering to ensure consistency in case ordering changes between batchings.

However, in many cases you know that this would never happen. For example, in acitivity feeds, you might want to batch-find activitites sorted by newest items. You know that new items cannot disrupt the ordering once batching started.

That being said, depending on your data model, deletions of records might screw you over during the batch-overlap detection, so use with caution.

## Installation

Add this line to your application's Gemfile:

    gem 'ar-find-in-batches-with-order'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ar-find-in-batches-with-order

## Usage

Usage is pretty much identical to find_each/find_each_in_batches, you'd just want to use the `:property_key` and `:direction` options to specify the ordering explicitly.

## Contributing

1. Fork it ( http://github.com/nambrot/ar-find-in-batches-with-order/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
