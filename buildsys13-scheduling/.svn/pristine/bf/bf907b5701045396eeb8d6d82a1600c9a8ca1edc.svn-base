PDF = paper.pdf
TEX = paper.tex abstract.tex introduction.tex 

pdf:	$(TEX) 
	pdflatex paper
	pdflatex paper
	bibtex paper
	pdflatex paper
	pdflatex paper

draft:	$(PDF)
	mv paper.pdf draft.pdf

clean:
	rm -f $(PS) $(PDF) *.dvi *.log *.aux *.bbl *.blg
