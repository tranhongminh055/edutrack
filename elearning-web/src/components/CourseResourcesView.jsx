import React, { useState, useEffect } from 'react';
import { collection, query, where, onSnapshot, addDoc, deleteDoc, doc, serverTimestamp } from 'firebase/firestore';
import { ref, uploadBytesResumable, getDownloadURL } from 'firebase/storage';
import { db, storage } from '../firebase';
import { ChevronRight, Plus, Trash2, Folder, Loader2, X, Save, CheckCircle, File, Download, ExternalLink, ChevronDown, RefreshCw, FolderPlus, Link, FileText, MoreVertical, UploadCloud } from 'lucide-react';

export default function CourseResourcesView({ course, role, email }) {
  const [resources, setResources] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showAddModal, setShowAddModal] = useState(false);
  const [activeTab, setActiveTab] = useState('resources'); // 'resources' | 'transfer'
  const [currentFolder, setCurrentFolder] = useState('root'); // folder path or 'root'
  const [openDropdownId, setOpenDropdownId] = useState(null);

  // Add Resource Form
  const [form, setForm] = useState({ title: '', url: '', type: 'document', folder: 'Course Materials', size: '1.2 MB' });
  const [saving, setSaving] = useState(false);
  const [toast, setToast] = useState(null);

  // Upload mode: 'file' (chọn file từ máy) | 'link' (dán link)
  const [uploadMode, setUploadMode] = useState('file');
  const [selectedFile, setSelectedFile] = useState(null);
  const [uploadProgress, setUploadProgress] = useState(0);

  const isLecturer = role === 'lecturer';

  // Format bytes to human readable size
  const formatBytes = (bytes) => {
    if (!bytes) return 'N/A';
    if (bytes < 1024) return `${bytes} B`;
    if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
    return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
  };

  const resetForm = () => {
    setForm({ title: '', url: '', type: 'document', folder: 'Course Materials', size: '1.2 MB' });
    setSelectedFile(null);
    setUploadProgress(0);
    setUploadMode('file');
  };

  const handleFileSelect = (e) => {
    const file = e.target.files?.[0];
    if (!file) return;
    setSelectedFile(file);
    // Auto-fill tiêu đề nếu chưa nhập
    setForm(f => ({ ...f, title: f.title || file.name.replace(/\.[^/.]+$/, '') }));
  };


  useEffect(() => {
    const q = query(collection(db, 'elearning_resources'), where('courseDocId', '==', course.docId));
    const unsub = onSnapshot(q, snap => {
      const dbResources = snap.docs.map(d => ({ id: d.id, ...d.data() }));

      // Default folders if collection is empty
      const defaultFolders = [
        { id: 'f1', title: 'Course Materials', type: 'folder', folder: 'root', createdBy: course.lecturerName || 'SYSTEM', size: '2 items', access: 'Entire site', createdAt: null },
        { id: 'f2', title: 'Assignments & Templates', type: 'folder', folder: 'root', createdBy: course.lecturerName || 'SYSTEM', size: '0 items', access: 'Entire site', createdAt: null }
      ];

      // Merge defaults with DB items
      const merged = [...defaultFolders];
      dbResources.forEach(res => {
        // If it's a file, put it inside its designated folder
        merged.push({
          id: res.id,
          title: res.title,
          url: res.url,
          type: res.type || 'document',
          folder: res.folder || 'Course Materials',
          createdBy: res.createdBy || course.lecturerName || 'N/A',
          size: res.size || '1.0 MB',
          access: 'Entire site',
          createdAt: res.createdAt
        });
      });

      // Update folder sizes dynamically
      defaultFolders.forEach(fold => {
        const count = merged.filter(item => item.folder === fold.title).length;
        fold.size = `${count} mục`;
      });

      setResources(merged);
      setLoading(false);
    }, () => setLoading(false));
    return unsub;
  }, [course.docId, course.lecturerName]);

  const handleAdd = async () => {
    // Validate theo chế độ upload
    if (!form.title) return;
    if (uploadMode === 'link' && !form.url) return;
    if (uploadMode === 'file' && !selectedFile) return;

    setSaving(true);
    try {
      let fileUrl = form.url;
      let fileSize = form.type === 'link' ? 'N/A' : '1.5 MB';
      let fileType = form.type;

      // Nếu chọn upload file từ máy -> đẩy lên Firebase Storage
      if (uploadMode === 'file' && selectedFile) {
        const safeName = selectedFile.name.replace(/[^a-zA-Z0-9._-]/g, '_');
        const storagePath = `elearning_resources/${course.docId}/${Date.now()}_${safeName}`;
        const storageRef = ref(storage, storagePath);
        const uploadTask = uploadBytesResumable(storageRef, selectedFile);

        fileUrl = await new Promise((resolve, reject) => {
          uploadTask.on(
            'state_changed',
            (snapshot) => {
              const progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
              setUploadProgress(Math.round(progress));
            },
            (error) => reject(error),
            async () => {
              const downloadURL = await getDownloadURL(uploadTask.snapshot.ref);
              resolve(downloadURL);
            }
          );
        });

        fileSize = formatBytes(selectedFile.size);
        fileType = 'document';
      }

      await addDoc(collection(db, 'elearning_resources'), {
        title: form.title,
        url: fileUrl,
        type: fileType,
        folder: form.folder,
        size: fileSize,
        fileName: uploadMode === 'file' && selectedFile ? selectedFile.name : null,
        courseDocId: course.docId,
        createdBy: course.lecturerName || email,
        createdAt: serverTimestamp()
      });
      setShowAddModal(false);
      resetForm();
      setToast('Đã tải tài liệu lên thành công!');
      setTimeout(() => setToast(null), 2500);
    } catch (e) {
      console.error(e);
      setToast('Lỗi khi tải lên: ' + (e.message || e));
      setTimeout(() => setToast(null), 3500);
    }
    setSaving(false);
  };


  const handleDelete = async (id) => {
    if (!window.confirm('Bạn có chắc chắn muốn xóa tài liệu này?')) return;
    try {
      await deleteDoc(doc(db, 'elearning_resources', id));
      setToast('Đã xóa tài liệu!');
      setTimeout(() => setToast(null), 2500);
    } catch (e) { console.error(e); }
  };

  // Get items in the current view level
  const displayedItems = resources.filter(item => {
    if (currentFolder === 'root') {
      return item.folder === 'root';
    } else {
      return item.folder === currentFolder;
    }
  });

  const getIcon = (type) => {
    switch (type) {
      case 'folder': return <Folder size={18} style={{ color: '#f59e0b', fill: '#f59e0b' }} />;
      case 'link': return <ExternalLink size={16} style={{ color: '#3b82f6' }} />;
      default: return <FileText size={16} style={{ color: '#ef4444' }} />;
    }
  };

  const s = {
    page: { backgroundColor: '#12141a', minHeight: '100vh', color: '#e0e0e0', fontFamily: 'Inter, sans-serif' },
    banner: { backgroundColor: '#cc0000', padding: '12px 20px', display: 'flex', alignItems: 'center', justifyContent: 'space-between', color: '#fff', fontSize: 14, fontWeight: 'bold' },
    container: { padding: '24px 30px', maxWidth: 1100, margin: '0 auto' },
    tabBtn: (active) => ({
      padding: '8px 16px',
      fontSize: 13,
      fontWeight: 600,
      background: active ? '#cc0000' : 'transparent',
      color: active ? '#fff' : '#9ca3af',
      border: 'none',
      borderRadius: '4px 4px 0 0',
      cursor: 'pointer',
      marginRight: 4
    }),
    table: { width: '100%', borderCollapse: 'collapse', marginTop: 12, border: '1px solid #2a2d38' },
    th: { background: '#1e2129', color: '#9ca3af', padding: '10px 16px', fontSize: 12, fontWeight: 600, textAlign: 'left', borderBottom: '2px solid #2a2d38' },
    td: { padding: '12px 16px', fontSize: 13, borderBottom: '1px solid #2a2d38', verticalAlign: 'middle' },
    actionBtnRed: {
      background: '#cc0000',
      color: '#fff',
      border: 'none',
      borderRadius: 3,
      padding: '4px 8px',
      fontSize: 11,
      fontWeight: 600,
      cursor: 'pointer',
      display: 'inline-flex',
      alignItems: 'center',
      gap: 4
    },
    overlay: { position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.6)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 1000 },
    modal: { background: '#1e2129', border: '1px solid #2a2d38', borderRadius: 10, padding: 24, width: 500 },
    input: { width: '100%', padding: '8px 12px', background: '#12141a', border: '1px solid #3f4350', borderRadius: 6, color: '#e0e0e0', fontSize: 13, outline: 'none' }
  };

  return (
    <div style={s.page}>
      <div style={s.banner}>
        <span>{course.courseId} {course.courseName} ({course.classGroup}) <ChevronRight size={16} style={{ margin: '0 8px', verticalAlign: 'middle' }} /> Resources</span>
      </div>

      <div style={s.container}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 16, color: '#9ca3af', fontSize: 13 }}>
          <span>Your role is {role === 'lecturer' ? 'Instructor' : 'Student'}</span>
        </div>

        {/* Sakai Tab Bar */}
        <div style={{ borderBottom: '2px solid #cc0000', display: 'flex' }}>
          <button style={s.tabBtn(activeTab === 'resources')} onClick={() => setActiveTab('resources')}>Site Resources</button>
          <button style={s.tabBtn(activeTab === 'transfer')} onClick={() => setActiveTab('transfer')}>Transfer Files</button>
        </div>

        {activeTab === 'resources' ? (
          <div style={{ marginTop: 20 }}>
            {/* Header Title */}
            <h3 style={{ fontSize: 18, fontWeight: 700, marginBottom: 12 }}>Site Resources</h3>

            {/* Path Breadcrumbs */}
            <div style={{ display: 'flex', alignItems: 'center', gap: 6, fontSize: 13, color: '#60a5fa', marginBottom: 16 }}>
              <span style={{ cursor: 'pointer' }} onClick={() => setCurrentFolder('root')}>All site files</span>
              <span>&gt;</span>
              <span style={{ cursor: 'pointer' }} onClick={() => setCurrentFolder('root')}>{course.courseId} Resources</span>
              {currentFolder !== 'root' && (
                <>
                  <span>&gt;</span>
                  <span style={{ color: '#e0e0e0', fontWeight: 600 }}>{currentFolder}</span>
                </>
              )}
            </div>

            {/* Top Toolbar Action Buttons */}
            <div style={{ display: 'flex', gap: 10, marginBottom: 16 }}>
              <button
                onClick={() => {
                  const blob = new Blob([JSON.stringify(resources, null, 2)], { type: 'application/json' });
                  const url = URL.createObjectURL(blob);
                  const a = document.createElement('a');
                  a.href = url;
                  a.download = `${course.courseId}_resources.json`;
                  a.click();
                }}
                style={{ padding: '6px 12px', background: '#2a2d38', border: '1px solid #3f4350', color: '#e0e0e0', borderRadius: 4, fontSize: 12, fontWeight: 600, cursor: 'pointer' }}
              >
                Download Zip
              </button>
              {isLecturer && (
                <button
                  onClick={() => setShowAddModal(true)}
                  style={{ padding: '6px 12px', background: '#cc0000', border: 'none', color: '#fff', borderRadius: 4, fontSize: 12, fontWeight: 600, cursor: 'pointer', display: 'flex', alignItems: 'center', gap: 4 }}
                >
                  <Plus size={14} /> Add Resource
                </button>
              )}
            </div>

            {/* Roster File Table List */}
            {loading ? (
              <div style={{ textAlign: 'center', padding: 60 }}><Loader2 size={32} style={{ color: '#cc0000', animation: 'spin 1s linear infinite' }} /></div>
            ) : (
              <table style={s.table}>
                <thead>
                  <tr>
                    <th style={{ ...s.th, width: 30 }}><input type="checkbox" disabled /></th>
                    <th style={s.th}>Title</th>
                    <th style={s.th}>Access</th>
                    <th style={s.th}>Created By</th>
                    <th style={s.th}>Modified</th>
                    <th style={s.th}>Size</th>
                  </tr>
                </thead>
                <tbody>
                  {/* Up Folder Row if we are nested */}
                  {currentFolder !== 'root' && (
                    <tr>
                      <td style={s.td}></td>
                      <td style={{ ...s.td, color: '#60a5fa', cursor: 'pointer', fontWeight: 600 }} onClick={() => setCurrentFolder('root')}>
                        Folder gốc (..)
                      </td>
                      <td style={s.td}></td>
                      <td style={s.td}></td>
                      <td style={s.td}></td>
                      <td style={s.td}></td>
                    </tr>
                  )}

                  {displayedItems.map(item => (
                    <tr key={item.id}>
                      <td style={s.td}><input type="checkbox" disabled /></td>
                      <td style={s.td}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                          {getIcon(item.type)}
                          {item.type === 'folder' ? (
                            <span
                              style={{ color: '#60a5fa', cursor: 'pointer', fontWeight: 600 }}
                              onClick={() => setCurrentFolder(item.title)}
                            >
                              {item.title}
                            </span>
                          ) : (
                            <a
                              href={item.url}
                              target="_blank"
                              rel="noopener noreferrer"
                              style={{ color: '#e0e0e0', textDecoration: 'none', fontWeight: 500 }}
                            >
                              {item.title}
                            </a>
                          )}

                          {/* Red Action Dropdown for Lecturer */}
                          {isLecturer && (
                            <div style={{ position: 'relative', marginLeft: 8 }}>
                              <button
                                onClick={(e) => {
                                  e.stopPropagation();
                                  setOpenDropdownId(openDropdownId === item.id ? null : item.id);
                                }}
                                style={s.actionBtnRed}
                              >
                                Actions <ChevronDown size={10} />
                              </button>

                              {openDropdownId === item.id && (
                                <div style={{ position: 'absolute', left: 0, top: '100%', background: '#1e2129', border: '1px solid #3f4350', borderRadius: 4, zIndex: 10, width: 140, boxShadow: '0 4px 12px rgba(0,0,0,0.5)', marginTop: 4 }}>
                                  {item.type === 'folder' && (
                                    <button
                                      onClick={() => {
                                        setForm(f => ({ ...f, folder: item.title }));
                                        setShowAddModal(true);
                                        setOpenDropdownId(null);
                                      }}
                                      style={{ width: '100%', padding: '8px 12px', background: 'none', border: 'none', color: '#e0e0e0', textAlign: 'left', fontSize: 12, cursor: 'pointer' }}
                                    >
                                      Add File Inside
                                    </button>
                                  )}
                                  {item.type !== 'folder' && (
                                    <button
                                      onClick={() => {
                                        handleDelete(item.id);
                                        setOpenDropdownId(null);
                                      }}
                                      style={{ width: '100%', padding: '8px 12px', background: 'none', border: 'none', color: '#ef4444', textAlign: 'left', fontSize: 12, cursor: 'pointer', display: 'flex', alignItems: 'center', gap: 6 }}
                                    >
                                      <Trash2 size={12} /> Delete File
                                    </button>
                                  )}
                                </div>
                              )}
                            </div>
                          )}
                        </div>
                      </td>
                      <td style={s.td}><span style={{ color: '#10b981', fontWeight: 600 }}>{item.access}</span></td>
                      <td style={s.td}>{item.createdBy}</td>
                      <td style={s.td}>
                        {item.createdAt ? (
                          item.createdAt.toDate?.()?.toLocaleString('vi-VN', { dateStyle: 'short', timeStyle: 'short' })
                        ) : 'Jun 5, 2026, 8:17 pm'}
                      </td>
                      <td style={s.td}>{item.size}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </div>
        ) : (
          <div style={{ padding: 40, textAlign: 'center', color: '#9ca3af' }}>
            <h4>Transfer Files via WebDAV</h4>
            <p style={{ fontSize: 13, marginTop: 10, maxWidth: 500, margin: '10px auto' }}>
              You can upload files in bulk to this site by using any WebDAV client (such as Cyberduck, WinSCP) configured with your university login.
            </p>
          </div>
        )}
      </div>

      {/* Add Resource Modal */}
      {showAddModal && (
        <div style={s.overlay} onClick={() => { if (!saving) { setShowAddModal(false); resetForm(); } }}>
          <div style={s.modal} onClick={e => e.stopPropagation()}>
            <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 16, alignItems: 'center' }}>
              <h3 style={{ fontSize: 16, fontWeight: 700, color: '#fff' }}>Upload File / Lesson</h3>
              <button onClick={() => { if (!saving) { setShowAddModal(false); resetForm(); } }} style={{ background: 'none', border: 'none', color: '#6b7280', cursor: 'pointer' }} disabled={saving}><X size={18} /></button>
            </div>

            {/* Upload Mode Selector */}
            <div style={{ display: 'flex', background: '#12141a', padding: 4, borderRadius: 6, marginBottom: 16 }}>
              <button
                onClick={() => setUploadMode('file')}
                style={{
                  flex: 1,
                  padding: '8px 12px',
                  fontSize: 12,
                  fontWeight: 600,
                  background: uploadMode === 'file' ? '#2a2d38' : 'transparent',
                  color: uploadMode === 'file' ? '#fff' : '#9ca3af',
                  border: 'none',
                  borderRadius: 4,
                  cursor: 'pointer',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  gap: 6
                }}
                disabled={saving}
              >
                <UploadCloud size={14} /> Tải file lên trực tiếp
              </button>
              <button
                onClick={() => { setUploadMode('link'); setForm(f => ({ ...f, type: 'link' })); }}
                style={{
                  flex: 1,
                  padding: '8px 12px',
                  fontSize: 12,
                  fontWeight: 600,
                  background: uploadMode === 'link' ? '#2a2d38' : 'transparent',
                  color: uploadMode === 'link' ? '#fff' : '#9ca3af',
                  border: 'none',
                  borderRadius: 4,
                  cursor: 'pointer',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  gap: 6
                }}
                disabled={saving}
              >
                <Link size={14} /> Nhập liên kết (URL)
              </button>
            </div>

            <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
              <div>
                <label style={{ fontSize: 12, color: '#9ca3af', display: 'block', marginBottom: 4 }}>Thư mục lưu trữ</label>
                <select style={s.input} value={form.folder} onChange={e => setForm(f => ({ ...f, folder: e.target.value }))} disabled={saving}>
                  <option value="Course Materials">Course Materials</option>
                  <option value="Assignments & Templates">Assignments & Templates</option>
                </select>
              </div>

              {uploadMode === 'file' ? (
                <div>
                  <label style={{ fontSize: 12, color: '#9ca3af', display: 'block', marginBottom: 4 }}>Chọn file từ máy tính *</label>
                  <div style={{
                    border: '2px dashed #3f4350',
                    borderRadius: 8,
                    padding: '20px',
                    textAlign: 'center',
                    background: '#12141a',
                    cursor: saving ? 'not-allowed' : 'pointer',
                    position: 'relative',
                    transition: 'border-color 0.2s'
                  }}
                    onClick={() => !saving && document.getElementById('file-picker-input').click()}
                  >
                    <input
                      type="file"
                      id="file-picker-input"
                      style={{ display: 'none' }}
                      onChange={handleFileSelect}
                      disabled={saving}
                    />
                    <UploadCloud size={32} style={{ color: '#9ca3af', margin: '0 auto 8px', display: 'block' }} />
                    <span style={{ fontSize: 13, color: '#e0e0e0', display: 'block', fontWeight: 500 }}>
                      {selectedFile ? selectedFile.name : 'Nhấp để chọn file cần upload'}
                    </span>
                    {selectedFile && (
                      <span style={{ fontSize: 11, color: '#9ca3af', display: 'block', marginTop: 4 }}>
                        Dung lượng: {formatBytes(selectedFile.size)}
                      </span>
                    )}
                  </div>
                </div>
              ) : (
                <div>
                  <label style={{ fontSize: 12, color: '#9ca3af', display: 'block', marginBottom: 4 }}>Đường dẫn tài liệu (Link Drive, OneDrive, v.v.) *</label>
                  <input style={s.input} value={form.url} onChange={e => setForm(f => ({ ...f, url: e.target.value }))} placeholder="https://..." disabled={saving} />
                </div>
              )}

              <div>
                <label style={{ fontSize: 12, color: '#9ca3af', display: 'block', marginBottom: 4 }}>Tiêu đề tài liệu / Lesson *</label>
                <input style={s.input} value={form.title} onChange={e => setForm(f => ({ ...f, title: e.target.value }))} placeholder="VD: Slide bài học Chương 1" disabled={saving} />
              </div>

              {uploadMode === 'link' && (
                <div>
                  <label style={{ fontSize: 12, color: '#9ca3af', display: 'block', marginBottom: 4 }}>Loại tài liệu</label>
                  <select style={s.input} value={form.type} onChange={e => setForm(f => ({ ...f, type: e.target.value }))} disabled={saving}>
                    <option value="link">Liên kết ngoài (URL)</option>
                    <option value="document">Tài liệu (PDF, Word, Slide)</option>
                  </select>
                </div>
              )}

              {/* Upload Progress Bar */}
              {saving && uploadMode === 'file' && uploadProgress > 0 && (
                <div style={{ marginTop: 8 }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 11, color: '#9ca3af', marginBottom: 4 }}>
                    <span>Đang tải lên...</span>
                    <span>{uploadProgress}%</span>
                  </div>
                  <div style={{ width: '100%', height: 6, background: '#12141a', borderRadius: 3, overflow: 'hidden' }}>
                    <div style={{ width: `${uploadProgress}%`, height: '100%', background: '#cc0000', transition: 'width 0.1s ease-out' }}></div>
                  </div>
                </div>
              )}

              <button
                style={{
                  display: 'inline-flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  gap: 8,
                  padding: '10px 16px',
                  opacity: saving ? 0.7 : 1,
                  background: '#cc0000',
                  color: '#fff',
                  border: 'none',
                  borderRadius: 6,
                  fontWeight: 600,
                  cursor: (saving || (uploadMode === 'file' && !selectedFile) || (uploadMode === 'link' && !form.url) || !form.title) ? 'not-allowed' : 'pointer',
                  marginTop: 8
                }}
                onClick={handleAdd}
                disabled={saving || (uploadMode === 'file' && !selectedFile) || (uploadMode === 'link' && !form.url) || !form.title}
              >
                {saving ? (
                  <>
                    <Loader2 size={16} style={{ animation: 'spin 1s linear infinite' }} />
                    {uploadMode === 'file' ? `Đang upload (${uploadProgress}%)` : 'Đang xử lý...'}
                  </>
                ) : (
                  <>
                    <Save size={16} />
                    {uploadMode === 'file' ? 'Upload File' : 'Lưu tài liệu'}
                  </>
                )}
              </button>
            </div>
          </div>
        </div>
      )}
      {toast && <div className="toast-notification success"><CheckCircle size={16} />{toast}</div>}
    </div>
  );
}
