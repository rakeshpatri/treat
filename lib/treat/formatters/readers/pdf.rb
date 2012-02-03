# encoding: utf-8
module Treat
  module Formatters
    module Readers
      # A wrapper for the Poppler pdf2text utility, which
      # extracts the text from a PDF file.
      class PDF
        # Read a PDF file using the Poppler pdf2text utility.
        # 
        # Options: none.
        def self.read(document, options = {})
          create_temp_file(:txt) do |tmp|
            `pdftotext #{document.file} #{tmp} `.strip
            f = File.read(tmp)
            f.gsub!("\t\r ", '')
            f.gsub!('-­‐', '-')
            f.gsub!("\n\n", '#keep#')
            f.gsub!("\n", ' ')
            f.gsub!(" ", ' ')
            f.gsub!('#keep#', "\n\n")
            document << Treat::Entities::Entity.from_string(f)
          end
          document
        end
      end
    end
  end
end
