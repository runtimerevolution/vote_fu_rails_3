# ActsAsVoteable
module Juixe
  module Acts #:nodoc:
    module Voteable #:nodoc:

      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        def acts_as_voteable
          has_many :votes, :as => :voteable, :dependent => :nullify

          include Juixe::Acts::Voteable::InstanceMethods
          extend  Juixe::Acts::Voteable::SingletonMethods
        end        
      end
      
      # This module contains class methods
      module SingletonMethods
        
        def count_tally(options={})
          count_by_sql("select count(*) from (#{construct_finder_sql(options_for_tally(options))}) tally")
        end
        
        # Calculate the vote counts for all voteables of my type.
        def tally(*args)
          # find(:all, options_for_tally(options.merge({:order =>"count DESC" })))
          if args.first.class == String
            conditions = args.shift
          else
            conditions = nil
          end
          options = args.first || {}

          options_for_tally(conditions, options).order("count DESC")
        end

        # 
        # Options:
        #  :start_at    - Restrict the votes to those created after a certain time
        #  :end_at      - Restrict the votes to those created before a certain time
        #  :conditions  - A piece of SQL conditions to add to the query
        #  :limit       - The maximum number of voteables to return
        #  :order       - A piece of SQL to order by. Eg 'votes.count desc' or 'voteable.created_at desc'
        #  :at_least    - Item must have at least X votes
        #  :at_most     - Item may not have more than X votes
        def options_for_tally (conditions, options = {})
            options.assert_valid_keys :start_at, :end_at, :conditions, :at_least, :at_most, :order, :limit, :offset, :novote

            scope = scope(:find)
            start_at = sanitize_sql(["#{Vote.table_name}.created_at >= ?", options.delete(:start_at)]) if options[:start_at]
            end_at = sanitize_sql(["#{Vote.table_name}.created_at <= ?", options.delete(:end_at)]) if options[:end_at]

            type_and_context = "#{Vote.table_name}.voteable_type = #{quote_value(base_class.name)}"

            options[:where] = [
              type_and_context,
              options[:conditions],
              start_at,
              end_at
            ]

            options[:where] = options[:where].compact.join(' AND ')
            #conditions = merge_conditions(conditions, scope[:conditions]) if scope
            
            select = "#{table_name}.*, COALESCE(COUNT(#{Vote.table_name}.id),0) AS count, COALESCE(SUM(#{cast_column('vote', 'int')}),0) as good, COALESCE(COUNT(#{Vote.table_name}.id) - SUM(#{cast_column('vote', 'int')}),0) as bad, MAX(#{Vote.table_name}.created_at) as created, MAX(#{Vote.table_name}.updated_at) as updated"
            joins = ["LEFT OUTER JOIN #{Vote.table_name} ON #{table_name}.#{primary_key} = #{Vote.table_name}.voteable_id"]
            #joins << scope[:joins] if scope && scope[:joins]
            no_vote = "COUNT(#{Vote.table_name}.id) > 0" unless options.delete(:novote)
            at_least  = sanitize_sql(["COUNT(#{Vote.table_name}.id) >= ?", options.delete(:at_least)]) if options[:at_least]
            at_most   = sanitize_sql(["COUNT(#{Vote.table_name}.id) <= ?", options.delete(:at_most)]) if options[:at_most]
            having = [no_vote, at_least, at_most].compact.join(' AND ')
            group_by  = "#{table_name}.id #{column_names_for_tally}"
            # group_by << " HAVING #{having}" unless having.blank?

            # { :select     => "#{table_name}.*, COALESCE(COUNT(#{Vote.table_name}.id),0) AS count, COALESCE(SUM(#{cast_column('vote', 'int')}),0) as good, COALESCE(COUNT(#{Vote.table_name}.id) - SUM(#{cast_column('vote', 'int')}),0) as bad, MAX(#{Vote.table_name}.created_at) as created, MAX(#{Vote.table_name}.updated_at) as updated", 
            #   :joins      => joins.join(" "),
            #   :conditions => conditions,
            #   :group      => group_by
            # }.update(options)          

            options_for_tally = select(select).where(conditions).where(options[:where]).joins(joins).group(group_by).having("COUNT(#{Vote.table_name}.id) > 0")
            options_for_tally = options_for_tally.having(having) unless having.blank?
            options_for_tally
        end
        
        #Correction for postgresql: http://allaboutruby.wordpress.com/2009/12/06/vote_fu-to-work-in-heroku-postgres/
        def column_names_for_tally
          if  ActiveRecord::Base.connection.adapter_name == 'MySQL'
           ''
          else
            ", " + column_names.map { |column| "#{table_name}.#{column}" }.join(", ")
          end
        end
        
        def cast_column column, type
          if  ActiveRecord::Base.connection.adapter_name == 'MySQL'
            "#{Vote.table_name}.#{column}"
          else
            "CAST(#{Vote.table_name}.#{column} as #{type})"
          end
        end
        
      end
      
      # This module contains instance methods
      module InstanceMethods
        def votes_for
          Vote.count(:all, :conditions => [
            "voteable_id = ? AND voteable_type = ? AND vote = ?",
            id, self.class.name, true
          ])
        end
        
        def votes_against
          Vote.count(:all, :conditions => [
            "voteable_id = ? AND voteable_type = ? AND vote = ?",
            id, self.class.name, false
          ])
        end
        
        def vote_difference
          self.votes_for - self.votes_against
        end
        
        # Same as voteable.votes.size
        def votes_count
          self.votes.size
        end
        
        def voters_who_voted
          voters = []
          self.votes.each { |v|
            voters << v.voter
          }
          voters
        end
        
        def voted_by?(voter)
          rtn = false
          if voter
            self.votes.each { |v|
              rtn = true if (voter.id == v.voter_id && voter.class.name == v.voter_type)
            }
          end
          rtn
        end
        
        
      end
    end
  end
end