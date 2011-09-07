Gem::Specification.new do |s|
  s.name = "vote_fu_rails_3"
  s.version = "0.0.12"
  s.date = "2011-09-07"
  s.summary = "Voting for ActiveRecord with multiple vote sources and advanced features."
  # s.email = "pete@peteonrails.com"
  # s.homepage = "http://blog.peteonrails.com/vote-fu"
  s.description = "VoteFu provides the ability to have multiple voting entities on an arbitrary number of models in ActiveRecord."
  # s.has_rdoc = false
  s.authors = ["Peter Jackson", "Cosmin Radoi", "Bence Nagy", "Rob Maddox"]
  s.files = [ "CHANGELOG.markdown",
              "MIT-LICENSE",
              "README.markdown",
              "generators/vote_fu",
              "generators/vote_fu/vote_fu_generator.rb",
              "generators/vote_fu/templates",
              "generators/vote_fu/templates/migration.rb",
              "init.rb",
              "lib/vote_fu.rb",
              "lib/acts_as_voteable.rb",
              "lib/acts_as_voter.rb",
              "lib/has_karma.rb",
              "lib/models/vote.rb",
              "lib/controllers/votes_controller.rb",
              "test/vote_fu_test.rb",
              "examples/votes_controller.rb",
              "examples/users_controller.rb",
              "examples/voteables_controller.rb",
              "examples/voteable.rb",
              "examples/voteable.html.erb",
              "examples/votes/_voteable_vote.html.erb",
              "examples/votes/create.rjs",
              "examples/routes.rb",
              "rails/init.rb"
  ]
  s.add_dependency("rails", ">= 3.0.0")
end
