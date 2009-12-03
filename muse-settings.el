;;; muse-settings -- load settings for individual directories. 

;; This file is not part of Emacs

;; Author: Phillip Lord <phillip.lord@newcastle.ac.uk>
;; Maintainer: Phillip Lord <phillip.lord@newcastle.ac.uk>
;; Website: http://www.russet.org.uk

;; COPYRIGHT NOTICE
;;
;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA. 


;;; Commentary:

;; Configuring muse can be fairly difficult. There are a lot of
;; different options that you might want to set. Currently, these get
;; set up in your .emacs; this is irritating because if you move the
;; project, the settings need to change. Also, you can't version the
;; wiki code and the lisp required for the publication process. This
;; file attempts to address this need, by allowing settings to be
;; placed in a local directory file and automatically loaded. 

;;; Usage:

;; Place this file in your `load-path' and put the following forms
;; into your .emacs
;;
;; (require 'muse-settings)
;; (muse-settings-enable)
;;
;; Secondly, put a file called settings-muse.el in the same directory
;; as your .muse files. This might contain
;;
;; (muse-settings-add-project 
;;  `("test-project" 
;;    (,(muse-settings-local-path) :default "index.html")
;;    (:base "test-project-html" :path ,(muse-settings-local-path))))
;;
;; (muse-settings-derive-style
;;  "test-project-html" "html"
;;  :header (muse-settings-local-header)
;;  :footer (muse-settings-local-footer))
;;
;; which will define a local project and a style, using "header.xml"
;; and "footer.xml" as their header and footer. 

;;; Notes:

;; My original thought was to do this all with buffer-local variables,
;; but for some reason muse doesn't like this. `muse-project-publish'
;; doesn't work. Instead, this uses the global variables muse
;; provides, and remembers which files it has already loaded. This
;; works nearly as well, but doesn't provide any degree of project
;; scoping which would be nice. 


;; some informative local variables
(defvar muse-settings-local-path nil
  "Defines the local directory of the settings file being loaded.")


(defvar muse-settings-loaded-files nil)

;; load a settings file from the local directory
(defun muse-settings-load-settings-file-maybe ()
  (interactive)
  (muse-settings-load-settings-file-maybe-from-dir
   (muse-settings-local-path)))

(defun muse-settings-load-settings-file-maybe-from-dir
  (muse-settings-local-path)
  (let* ((muse-settings-load-file
          (if muse-settings-local-path
              (expand-file-name
               "settings-muse.el")
            muse-settings-local-path)))
    (unless (member 
             muse-settings-load-file
             muse-settings-loaded-files)
      (when (and muse-settings-load-file
                 (file-exists-p muse-settings-load-file))
        (load-file muse-settings-load-file))
      (add-to-list 'muse-settings-loaded-files muse-settings-load-file))))


(defun muse-settings-local-path()
  "Returns the current path or nil. if there is none."
  (if (buffer-file-name)
      (expand-file-name
       (file-name-directory
        (buffer-file-name)))
    default-directory))

(defun muse-settings-add-project (project)
  (add-to-list 'muse-project-alist project))


(defun muse-settings-derive-style (name base-name &rest elements)
  (apply 'muse-derive-style name base-name elements))

(defun muse-settings-local-file (name)
  "Return the name of a file in the local directory"
  (expand-file-name name muse-settings-local-path))

(defun muse-settings-local-header () 
  (muse-settings-local-file "header.xml"))

(defun muse-settings-local-footer ()
  (muse-settings-local-file "footer.xml"))

(defun muse-settings-html-local-style()
  "Return an HTML header style tag.

This is meant for use in the HTML header. It returns a tag with
CSS style sheet from the file style.css in the same directory.

This simplifies deployment as it means that the CSS file need be
placed on the websever when updated. However, it has the
disadvantage that the entire project needs rebuilding following a
change and the header must be downloaded for each file, rather
than cached."
  (concat
   "<style type=\"text/css\">"
   (with-temp-buffer
     (insert-file-contents 
      (concat (muse-settings-local-path)
              "style.css"))
     (buffer-string))
   "</style>"))


(defun muse-settings-enable ()
  (interactive)
  (add-hook 'muse-mode-hook 'muse-settings-load-settings-file-maybe))

(defun muse-settings-disable ()
  (interactive)
  (remove-hook 'muse-mode-hook 'muse-settings-load-settings-file-maybe))

;; muse publish checks a style exists before it loads the file. In
;; batch this can cause crashes as no other muse files in the
;; directory may have been loaded. Just run a check first.
(defadvice muse-publish-file
  (before muse-settings-advice activate)
  (muse-settings-load-settings-file-maybe-from-dir
   default-directory))


(provide 'muse-settings)