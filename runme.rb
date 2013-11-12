require './dirscanner'
SRC_DIR = 'bpd'
OUT_DIR = 'bpd_scraped'

d = DirectoryScraper.new(SRC_DIR)
d.build_site_from_content(OUT_DIR)
