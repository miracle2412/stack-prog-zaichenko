require 'find'
require 'digest'
require 'json'

def get_file_hash(file_path)
  digest = Digest::SHA256.new
  File.open(file_path, 'rb') do |file|
    while chunk = file.read(1024 * 1024)
      digest.update(chunk)
    end
  end
  digest.hexdigest
end

def scan_files(root_dir)
  files_data = []
  Find.find(root_dir) do |path|
    next if File.directory?(path)
    file_info = {
      path: path,
      size: File.size(path),
      inode: File.stat(path).ino
    }
    files_data << file_info
  end
  files_data
end

def group_duplicates(files_data)
  file_hashes = Hash.new { |hash, key| hash[key] = [] }
  files_data.each do |file|
    hash = get_file_hash(file[:path])
    file_hashes[hash] << file
  end
  file_hashes.select { |_, files| files.size > 1 }
end

def generate_report(root_dir, output_file = 'duplicates.json')
  files_data = scan_files(root_dir)
  duplicates = group_duplicates(files_data)

  groups = duplicates.map do |hash, files|
    size = files.first[:size]
    saved_if_dedup = size * (files.size - 1)
    {
      size_bytes: size,
      saved_if_dedup_bytes: saved_if_dedup,
      files: files.map { |file| file[:path] }
    }
  end

  report = {
    scanned_files: files_data.size,
    groups: groups
  }

  File.open(output_file, 'w') do |file|
    file.write(JSON.pretty_generate(report))
  end
  puts "Звіт збережено в #{output_file}"
end

generate_report('C:\Users\Admin\RubymineProjects\lab_3')

