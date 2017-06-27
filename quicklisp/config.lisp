;;;; config.lisp

(in-package #:ql-config)

(defun config-value-file-pathname (path)
  (let ((bad-position (position #\Space path)))
    (when bad-position
      (error "Space not allowed at position ~D in ~S"
             bad-position
             path)))
  (let* ((space-path (substitute #\Space #\/ path))
         (split (split-spaces space-path))
         (directory-parts (butlast split))
         (name (first (last split)))
         (base (qmerge "config/")))
     (merge-pathnames
      (make-pathname :name name
                     :type "txt"
                     :directory (list* :relative directory-parts))
      base)))

(defun config-paths (&optional (path-string "**/*"))
  "Return all config paths that match PATH-STRING."
  (let* ((base (qmerge "config/"))
         (pathname-to-match (merge-pathnames
                             (merge-pathnames
                              (make-pathname :type "txt")
                              path-string)
                             base))
         (pathnames (directory pathname-to-match)))
    (mapcar (lambda (p)
              (let ((enough-p (enough-namestring p base)))
                ;; Strip off the .txt
                (namestring (make-pathname :directory (pathname-directory enough-p)
                                           :name (pathname-name enough-p)))))
            pathnames)))

(defun config-value (path)
  (let ((file (config-value-file-pathname path)))
    (with-open-file (stream file :if-does-not-exist nil)
      (when stream
        (values (read-line stream nil))))))

(defun (setf config-value) (new-value path)
  (let ((file (config-value-file-pathname path)))
    (typecase new-value
      (null
       (delete-file-if-exists file))
      (string
       (ensure-directories-exist file)
       (with-open-file (stream file :direction :output
                               :if-does-not-exist :create
                               :if-exists :rename-and-delete)
         (write-line new-value stream)))
      (t
       (error "Bad config value ~S; must be a string or NIL" new-value)))))
