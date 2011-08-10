Rake::TaskManager.class_eval do
  def remove_task(task_name)
    @tasks.delete(task_name.to_s)
  end
end
class Rake::Task
  def abandon
    @actions.clear
  end
end

def remove_task(task_name)
  Rake::Task[task_name].abandon
  Rake::Task[task_name].prerequisites.clear
  Rake.application.remove_task(task_name)
  Rake::Task[:default].prerequisites.delete(task_name.to_s)
rescue RuntimeError => e
  if e.message =~ /Don't know how to build/
    # ok, task doesn't exist, carry on
  else
    raise e
  end
end

def remove_plugin_task(name)
  remove_task("#{name}:pull")
  remove_task("#{name}:install")
  remove_task(name)
  file(File.expand_path("tmp/#{name}") => "tmp").clear
end

def override_plugin_task(name, repo=nil, &block)
  remove_plugin_task name
  vim_plugin_task name, repo, &block
end

def extend_plugin_task(name, &block)
  task "#{name}:install" do
    yield block
  end
end

# don't want wycats' fork, i want the source
override_plugin_task "nerdtree", "git://github.com/scrooloose/nerdtree.git"

remove_plugin_task "jslint"
#vim_plugin_task "jshint", "https://github.com/wookiehangover/jshint.vim.git"

# this is not useful to me
remove_plugin_task "unimpaired"
# this is interesting but i don't need it
remove_plugin_task "searchfold"
# i don't use scala
remove_plugin_task "scala"
# i guess this is cool but again, not necessary
remove_plugin_task "conque"
# what the fuck, really, carlhuda?
remove_plugin_task "arduino"

vim_plugin_task "vim-ruby", "https://github.com/vim-ruby/vim-ruby.git"
vim_plugin_task "ragtag", "git://github.com/tpope/vim-ragtag.git"
# vim_plugin_task "repeat", "git://github.com/tpope/vim-repeat.git"
# vim_plugin_task "liquid", "git://github.com/vim-ruby/vim-ruby.git"
# vim_plugin_task "ragel", "https://github.com/jayferd/ragel.vim.git"
vim_plugin_task "scss", "https://github.com/cakebaker/scss-syntax.vim.git"
vim_plugin_task "sinatra", "https://github.com/hallison/vim-ruby-sinatra.git"
vim_plugin_task "less", "git://gist.github.com/369178.git"
# vim_plugin_task "camelcasemotion", "https://github.com/vim-scripts/camelcasemotion.git"
#vim_plugin_task "zencoding", "https://github.com/mattn/zencoding-vim.git"
vim_plugin_task "session", "https://github.com/vim-scripts/session.vim--Odding.git"
vim_plugin_task "delimitMate", "https://github.com/Raimondi/delimitMate.git"
#vim_plugin_task "css-color", "https://github.com/ap/vim-css-color.git" do
#  sh "cp after/syntax/{css,less}.vim"
#  sh "cp after/syntax/{css,scss}.vim"
#end
#vim_plugin_task "bccalc", "https://github.com/vim-scripts/bccalc.vim.git"
vim_plugin_task "vim-git", "https://github.com/tpope/vim-git.git" do
  content = File.read('ftplugin/gitcommit.vim')
  # this isn't 1976, let's be reasonable here
  content.gsub!('setlocal textwidth=72', 'setlocal textwidth=80')
  File.open('ftplugin/gitcommit.vim', "w") {|f| f.write(content) }
end
## -- do NOT enable this, it seems to undo a lot of plugins or something --
#vim_plugin_task "gundo", "https://github.com/sjl/gundo.vim"

vim_plugin_task "autotag", "https://github.com/vim-scripts/AutoTag.git"

# vim_plugin_task "tabmerge" do
#   sh "curl 'http://www.vim.org/scripts/download_script.php?src_id=8828' > plugin/Tabmerge.vim"
# end

vim_plugin_task "html5-syntax",     "git://github.com/othree/html5-syntax.vim.git"

vim_plugin_task "lesscss",          "git://gist.github.com/161047.git" do
  FileUtils.cp "tmp/lesscss/less.vim", "syntax"
end

vim_plugin_task "html5",            "git://github.com/othree/html5.vim.git" do
  Dir.chdir "tmp/html5" do
    sh "make install"
  end
end

vim_plugin_task "bufexplorer",      "git://github.com/vim-scripts/bufexplorer.zip.git"

# Show marks in a column on the side
vim_plugin_task "showmarks", "https://github.com/vim-scripts/ShowMarks.git"

override_plugin_task "molokai" do
  sh "curl https://raw.github.com/mrtazz/molokai.vim/master/colors/molokai.vim > colors/molokai.vim"
  File.open("colors/molokai.vim", "a") do |f|
    f.puts "hi SpecialComment  guifg=#6E858A               gui=bold"
    f.puts "hi Comment         guifg=#6E858A"
    # Normal bg color is #1B1D1E
    f.puts "hi ColorColumn     guibg=#17191A" # slightly darker
    # f.puts "hi ColorColumn     guibg=#121414"
    f.puts "hi clear NonText"
    f.puts "hi NonText term=reverse guifg=#3C4143"
    f.puts "hi MatchParen gui=bold guifg=#FD971F guibg=#000000"
  end
end

vim_plugin_task "tomorrow-night" do
  sh "curl https://raw.github.com/ChrisKempson/Tomorrow-Theme/master/Vim/Tomorrow-Night.vim > colors/tomorrow-night.vim"
end

vim_plugin_task "nerdtree_command-t" do
  File.open("after/plugin/nerdtree_command-t.vim", "w") do |f|
    f.puts <<-HACK
" NERDTree and Command-T compatibility hack
"
" Open an empty buffer and then start a real NERDTree, but only if
" vim was opened with a single directory as the first argument.
" The empty buffer gives command-t a buffer in which to open a
" file, rather than having it fail to clobber the default directory browser.
"
" This preserves the NERDTree netrw browsing replacement, but overrides it
" when vim is first loading.
"
" This script is in after/plugins since it needs to add the autocmd
" override after the plugin's autocmds are loaded and defined.

function ReplaceNERDTreeIfDirectory()
  if argc() == 0 || (argc() == 1 && isdirectory(argv(0)))
    " replace the directory browser with an empty buffer
    enew
    " and open a regular NERDTree instead
    NERDTree
  endif
endfunction

augroup NERDTreeHijackNetrw
  au VimEnter * call ReplaceNERDTreeIfDirectory()
augroup END
    HACK
  end
end

# disable formatoptions "o" to disallow comment continuation
# in various ftplugin that enable it
vim_plugin_task "fo_minus_o" do
  Dir.mkdir "after/ftplugin" unless File.directory?("after/ftplugin")
  %w(ruby vim coffee gitconfig javascript).each do |filetype|
    File.open("after/ftplugin/#{filetype}.vim", "w+") do |f|
      f.puts "setlocal formatoptions-=o"
    end
  end
end

vim_plugin_task "lilypond" do
  Dir.mkdir "compiler" unless File.directory?("compiler")
  files = %w(
    compiler/lilypond.vim
    ftdetect/lilypond.vim
    ftplugin/lilypond.vim
    indent/lilypond.vim
    syntax/lilypond-words
    syntax/lilypond-words.vim
    syntax/lilypond.vim
  )
  for file in files
    sh "curl https://raw.github.com/vault/dotfiles/master/.vim/bundle/lilypond/#{file} > #{file}"
  end
end

vim_plugin_task "simplefold", "https://github.com/vim-scripts/simplefold.git"

#------

=begin
plugins = %w(
  ack
  align
  cucumber
  delimitMate
  endwise
  #fugitive
  gist-vim
  html5
  html5-syntax
  indent_object
  jslint
  jshint
  markdown
  nerdcommenter
  puppet
  ragtag
  rails
  vim-ruby
  showmarks
  snipmate
  syntastic
  taglist
  vim-git
  autotag
  rspec
  supertab
  simplefold
  surround
  nerdtree
  command_t
  ruby-sinatra
)
plugins.each do |plugin|
  remove_plugin_task plugin unless plugin =~ /^#/
end

`mkdir -p after/plugin`
=end