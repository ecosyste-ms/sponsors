class SponsorshipGraph
  def self.mutual_pair_count(active_only: true)
    ActiveRecord::Base.connection.select_value(<<~SQL).to_i
      SELECT count(*)
      FROM sponsorships s1
      JOIN sponsorships s2
        ON s2.funder_id = s1.maintainer_id
       AND s2.maintainer_id = s1.funder_id
      WHERE s1.funder_id < s1.maintainer_id
        #{"AND s1.status = 'active' AND s2.status = 'active'" if active_only}
    SQL
  end

  def self.mutual_pairs(active_only: true)
    ActiveRecord::Base.connection.select_rows(<<~SQL)
      SELECT a.login, b.login
      FROM sponsorships s1
      JOIN sponsorships s2
        ON s2.funder_id = s1.maintainer_id
       AND s2.maintainer_id = s1.funder_id
      JOIN accounts a ON a.id = s1.funder_id
      JOIN accounts b ON b.id = s1.maintainer_id
      WHERE s1.funder_id < s1.maintainer_id
        #{"AND s1.status = 'active' AND s2.status = 'active'" if active_only}
      ORDER BY a.login, b.login
    SQL
  end

  def self.triangles
    ActiveRecord::Base.connection.select_rows(<<~SQL)
      SELECT a.login, b.login, c.login
      FROM sponsorships s1
      JOIN sponsorships s2 ON s2.funder_id = s1.maintainer_id
      JOIN sponsorships s3 ON s3.funder_id = s2.maintainer_id
                          AND s3.maintainer_id = s1.funder_id
      JOIN accounts a ON a.id = s1.funder_id
      JOIN accounts b ON b.id = s1.maintainer_id
      JOIN accounts c ON c.id = s2.maintainer_id
      WHERE s1.status = 'active' AND s2.status = 'active' AND s3.status = 'active'
        AND s1.funder_id < s1.maintainer_id
        AND s1.funder_id < s2.maintainer_id
        AND s1.maintainer_id <> s2.maintainer_id
      ORDER BY a.login, b.login, c.login
    SQL
  end

  def self.cluster_for(account)
    strongly_connected_components.find { |component| component.size > 2 && component.include?(account.login) }
  end

  def self.active_edges
    funder_ids = Sponsorship.active.distinct.pluck(:funder_id)
    maintainer_ids = Sponsorship.active.distinct.pluck(:maintainer_id)
    ids = funder_ids & maintainer_ids
    Sponsorship.active.where(funder_id: ids, maintainer_id: ids).pluck(:funder_id, :maintainer_id)
  end

  def self.loop_sponsorship_count
    edges = active_edges
    graph = Hash.new { |h, k| h[k] = [] }
    edges.each { |funder_id, maintainer_id| graph[funder_id] << maintainer_id }

    component_of = {}
    tarjan(graph).each do |component|
      component.each { |id| component_of[id] = component } if component.size > 1
    end
    edges.count { |funder_id, maintainer_id| component_of[funder_id] && component_of[funder_id].equal?(component_of[maintainer_id]) }
  end

  def self.strongly_connected_components
    graph = Hash.new { |h, k| h[k] = [] }
    active_edges.each do |funder_id, maintainer_id|
      graph[funder_id] << maintainer_id
    end

    components = tarjan(graph).select { |component| component.size > 1 }
    logins = Account.where(id: components.flatten).pluck(:id, :login).to_h
    components.map { |component| component.map { |id| logins[id] }.sort }.sort_by { |c| [-c.size, c.first] }
  end

  def self.tarjan(graph)
    index = {}
    lowlink = {}
    on_stack = {}
    stack = []
    counter = 0
    components = []

    graph.keys.each do |start|
      next if index.key?(start)
      work = [[start, 0]]
      until work.empty?
        node, i = work.last
        if i.zero?
          index[node] = counter
          lowlink[node] = counter
          counter += 1
          stack.push(node)
          on_stack[node] = true
        end
        advanced = false
        neighbours = graph.fetch(node, [])
        while i < neighbours.length
          neighbour = neighbours[i]
          i += 1
          if !index.key?(neighbour)
            work.last[1] = i
            work.push([neighbour, 0])
            advanced = true
            break
          elsif on_stack[neighbour]
            lowlink[node] = [lowlink[node], index[neighbour]].min
          end
        end
        next if advanced

        if lowlink[node] == index[node]
          component = []
          loop do
            member = stack.pop
            on_stack[member] = false
            component << member
            break if member == node
          end
          components << component
        end
        work.pop
        unless work.empty?
          parent = work.last.first
          lowlink[parent] = [lowlink[parent], lowlink[node]].min
        end
      end
    end

    components
  end
end
