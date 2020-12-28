#! /usr/bin/env nix-shell
#! nix-shell -i ruby -p ruby_2_7 rubyPackages_2_7.thor rubyPackages_2_7.activesupport

require 'active_support/core_ext/string/filters'
require 'date'
require 'thor'

# This module describes the standard bzip2 (de)compression that we'd use.
module BZip2
  CMD = "bzip2"

  def self.compress
    "#{CMD} -cz"
  end

  def self.decompress
    "#{CMD} -d"
  end
end

# This module describes the standard xz (de)compression that we'd use.
module XZ
  CMD = "xz"

  def self.compress
    "#{CMD} -cz -T0"
  end

  def self.decompress
    "#{CMD} -d -T0"
  end
end

# This module describes the standard zstd (de)compression that we'd use.
module ZStandard
  CMD = "zstd"

  def self.compress
    "#{CMD} -cz -T0"
  end

  def self.decompress
    "#{CMD} -d -T0"
  end
end

# This is shared logic across all backup types.
class Backup
  attr_reader :compressor, :destination, :start

  def initialize(compressor: 'xz', destination: nil)
    @compressor = compressor
    @destination = destination
    @start = DateTime.now
  end

  def get_compressor
    case compressor
    when 'xz' then XZ
    when 'bz2' then BZip2
    when 'zstd' then ZStandard
    else raise "Unknown compression algorithm #{compressor}"
    end
  end

  def timestamp
    start.strftime("%Y%m%d-%H%M%S")
  end

  def backup
    `#{backup_cmd} | #{get_compressor.compress} > #{filename}`
  end
end

# This describes how a tar backup would be handled.
class TarBackup < Backup
  include XZ

  attr_reader :dir, :incremental

  def initialize(compressor: 'xz', destination: nil, dir: nil, incremental: false)
    super(compressor: compressor, destination: destination)
    @dir = dir
    @incremental = incremental
  end

  # This method builds the tar command to build the backup.
  def backup_cmd
    <<~CMD.squish
    tar -C '#{dir}'
      -c
      -v
      -p
      --xattrs
      --numeric-owner
      --exclude-backups
      --exclude-vcs-ignore
      --exclude=*.log
      --exclude=.bundle/cache
      --exclude=.cache
      --exclude=.config/google-chrome
      --exclude=.local/share/Trash
      --exclude=.mozilla
      --exclude=.npm/_cacache
      --exclude=.npm/_logs
      --exclude=.solargraph
      --exclude=go/pkg
      --exclude=node_modules
      --exclude=public/packs*
      --exclude=result
      --exclude=tmp/*
      .
    CMD
  end

  def filename
    basename = File.basename(dir)
    File.join(destination, "#{basename}-#{timestamp}.tar.#{compressor}")
  end
end

class BackupCLI < Thor
  def self.exit_on_failure?
    true
  end

  desc 'backup_files DIR', 'Back up files located in the given directory'
  option :incremental, type: :boolean, aliases: :i
  option :compress, type: :string, aliases: :c
  option :destination, type: :string, aliases: :d
  def backup_files(dir)
    TarBackup.new(
      compressor: options[:compress],
      destination: options[:destination],
      dir: dir,
      incremental: options[:incremental]
    ).backup
  end
end

BackupCLI.start(ARGV)
