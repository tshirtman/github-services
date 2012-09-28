# shameless ripoff cia.vc, since they are dead, trying to make use of the new
# api
# server is lgpl and available at tshirtman/kgb

class Service::KGB < Service
  string :project, :branch, :module
  boolean :long_url, :full_commits
  white_list :project, :branch, :module

  def repository data
    if !(name = data['project'].to_s).empty?
      name
    else
      payload['repository']['name']
    end
  end

  def branch data
    if !(branch = data['branch'].to_s).empty?
      branch % branch_name
    else
      ref_name
    end
  end

  def receive_issues
    author = payload['author']['login']
    url = payload['url']
    event = payload['event']
    title = payload['title']
    milestone = payload['milestone']

    deliver(repository, 'issues', "issue:" + title +
            "|author:" + author + "|action:" + event)
  end

  def receive_issue_comment
    #TODO
  end

  def receive_commit_comment
    #TODO
  end

  def receive_pull_request
    #TODO
  end

  def receive_gollum
    #TODO
  end

  def receive_watch
    #TODO
  end

  def receive_download
    #TODO
  end

  def receive_fork
    #TODO
  end

  def receive_fork_apply
    #TODO
  end

  def receive_member
    #TODO
  end

  def receive_public
    #TODO
  end

  def receive_status
    #TODO
  end

  def receive_push
    commits = payload['commits']
    module_name = data['module'].to_s

    if commits.size > 5
      message = build_kgb_commit(
        repository data,
        branch(data),
        payload['after'],
        commits.last,
        module_name,
        commits.size - 1)

      deliver(message)

    else
      commits.each do |commit|
        sha1 = commit['id']
        message = build_kgb_commit(repository, branch, sha1, commit, module_name)
        deliver(message)
      end
    end
  end

  def deliver(repository, signal, message)
    url = 'kgb.tshirtman.fr'
    http.ssl = false

    http.header['method'] = 'POST'
    body = JSON.generate({
      'repository' => repository,
      'signal' => signal,
      'content' => message
    })

    http_post url, body
  end

  def build_kgb_commit(repository, branch, sha1, commit, module_name, size = 1)
    log_lines = commit['message'].split("\n")
    log = log_lines.shift
    log << " (+#{size} more commits...)" if size > 1

    files      = commit['modified'] + commit['added'] + commit['removed']
    tiny_url   = data['long_url'].to_i == 1 ? commit['url'] : shorten_url(commit['url'])

    log << " - #{tiny_url}"

    if data['full_commits'].to_i == 1
      log_lines.each do |log_line|
        log << "\n" << log_line
      end
    end

    repository +
      branch +
      module_name +
      commit['author']['name'] +
      CGI.escapeHTML(log) +
      files +
      commit['url'] +
      sha1
  end
end
