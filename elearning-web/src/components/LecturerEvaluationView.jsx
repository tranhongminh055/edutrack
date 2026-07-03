import React, { useState, useEffect } from 'react';
import { Upload, Download, Trash2, FileText, Loader2 } from 'lucide-react';
import { uploadLecturerEvaluationForm, getLecturerEvaluationForms, deleteLecturerEvaluationForm } from '../services/resourceService';

function LecturerEvaluationView({ role, email }) {
  const [forms, setForms] = useState([]);
  const [loading, setLoading] = useState(true);
  const [uploading, setUploading] = useState(false);
  const [uploadProgress, setUploadProgress] = useState(0);
  const [selectedFile, setSelectedFile] = useState(null);

  useEffect(() => {
    loadForms();
  }, []);

  const loadForms = async () => {
    try {
      const data = await getLecturerEvaluationForms();
      setForms(data);
    } catch (err) {
      console.error('Error loading forms:', err);
    } finally {
      setLoading(false);
    }
  };

  const handleFileSelect = (e) => {
    const file = e.target.files[0];
    if (file) {
      setSelectedFile(file);
    }
  };

  const handleUpload = async () => {
    if (!selectedFile) return;

    setUploading(true);
    setUploadProgress(0);

    try {
      await uploadLecturerEvaluationForm(selectedFile, (pct) => {
        setUploadProgress(pct);
      });
      setSelectedFile(null);
      await loadForms();
      alert('Đã tải lên phiếu đánh giá thành công!');
    } catch (err) {
      console.error('Upload error:', err);
      alert('Lỗi khi tải lên: ' + err.message);
    } finally {
      setUploading(false);
      setUploadProgress(0);
    }
  };

  const handleDelete = async (formId, storagePath, fileName) => {
    if (!confirm(`Bạn có chắc muốn xóa phiếu đánh giá "${fileName}"?`)) return;

    try {
      await deleteLecturerEvaluationForm(formId, storagePath);
      await loadForms();
      alert('Đã xóa phiếu đánh giá thành công!');
    } catch (err) {
      console.error('Delete error:', err);
      alert('Lỗi khi xóa: ' + err.message);
    }
  };

  const formatFileSize = (bytes) => {
    if (bytes < 1024) return bytes + ' B';
    if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + ' KB';
    return (bytes / (1024 * 1024)).toFixed(1) + ' MB';
  };

  const formatDate = (timestamp) => {
    if (!timestamp) return 'N/A';
    const date = timestamp.toDate ? timestamp.toDate() : new Date(timestamp);
    return date.toLocaleDateString('vi-VN', { 
      day: '2-digit', 
      month: '2-digit', 
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    });
  };

  if (loading) {
    return (
      <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', height: '100%' }}>
        <Loader2 style={{ width: 40, height: 40, color: '#3b82f6', animation: 'spin 1s linear infinite' }} />
        <span style={{ marginTop: 16, color: '#64748b' }}>Đang tải dữ liệu...</span>
      </div>
    );
  }

  return (
    <div style={{ padding: 24, maxWidth: 1200, margin: '0 auto' }}>
      <div style={{ marginBottom: 32 }}>
        <h1 style={{ fontSize: 28, fontWeight: 700, color: '#1e293b', marginBottom: 8 }}>
          Phiếu Đánh Giá Giảng Viên
        </h1>
        <p style={{ color: '#64748b', fontSize: 14 }}>
          {role === 'lecturer' ? 'Quản lý phiếu đánh giá giảng viên' : 'Xem và tải xuống phiếu đánh giá'}
        </p>
      </div>

      {role === 'lecturer' && (
        <div style={{ 
          background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
          borderRadius: 16,
          padding: 24,
          marginBottom: 32,
          boxShadow: '0 4px 6px -1px rgba(0, 0, 0, 0.1)'
        }}>
          <h3 style={{ color: 'white', fontSize: 18, fontWeight: 600, marginBottom: 16 }}>
            Tải lên Phiếu Đánh Giá Mới
          </h3>
          
          <div style={{ background: 'rgba(255, 255, 255, 0.1)', borderRadius: 12, padding: 20 }}>
            <input
              type="file"
              id="evaluationFile"
              accept=".pdf,.doc,.docx"
              onChange={handleFileSelect}
              style={{ display: 'none' }}
            />
            <label
              htmlFor="evaluationFile"
              style={{
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                gap: 12,
                padding: 24,
                border: '2px dashed rgba(255, 255, 255, 0.3)',
                borderRadius: 8,
                cursor: 'pointer',
                transition: 'all 0.2s'
              }}
              onMouseEnter={(e) => e.target.style.background = 'rgba(255, 255, 255, 0.1)'}
              onMouseLeave={(e) => e.target.style.background = 'transparent'}
            >
              <Upload style={{ width: 24, height: 24, color: 'white' }} />
              <span style={{ color: 'white', fontSize: 14 }}>
                {selectedFile ? selectedFile.name : 'Chọn file phiếu đánh giá (PDF, DOC, DOCX)'}
              </span>
            </label>

            {selectedFile && (
              <div style={{ marginTop: 16 }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 8 }}>
                  <span style={{ color: 'white', fontSize: 12 }}>{selectedFile.name}</span>
                  <span style={{ color: 'rgba(255, 255, 255, 0.7)', fontSize: 12 }}>
                    {formatFileSize(selectedFile.size)}
                  </span>
                </div>
                
                {uploading ? (
                  <div style={{ marginBottom: 16 }}>
                    <div style={{ 
                      height: 8, 
                      background: 'rgba(255, 255, 255, 0.2)', 
                      borderRadius: 4,
                      overflow: 'hidden'
                    }}>
                      <div style={{ 
                        height: '100%', 
                        background: 'white', 
                        borderRadius: 4,
                        width: `${uploadProgress}%`,
                        transition: 'width 0.3s'
                      }} />
                    </div>
                    <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 4 }}>
                      <span style={{ color: 'white', fontSize: 12 }}>Đang tải lên...</span>
                      <span style={{ color: 'white', fontSize: 12 }}>{uploadProgress.toFixed(0)}%</span>
                    </div>
                  </div>
                ) : (
                  <button
                    onClick={handleUpload}
                    disabled={uploading}
                    style={{
                      width: '100%',
                      padding: 12,
                      background: 'white',
                      color: '#667eea',
                      border: 'none',
                      borderRadius: 8,
                      fontWeight: 600,
                      cursor: uploading ? 'not-allowed' : 'pointer',
                      fontSize: 14
                    }}
                  >
                    {uploading ? 'Đang tải lên...' : 'Tải lên'}
                  </button>
                )}
              </div>
            )}
          </div>
        </div>
      )}

      <div style={{ background: 'white', borderRadius: 16, boxShadow: '0 1px 3px rgba(0, 0, 0, 0.1)' }}>
        <div style={{ padding: 20, borderBottom: '1px solid #e2e8f0' }}>
          <h3 style={{ fontSize: 18, fontWeight: 600, color: '#1e293b' }}>
            Danh Sách Phiếu Đánh Giá
          </h3>
        </div>

        {forms.length === 0 ? (
          <div style={{ padding: 48, textAlign: 'center' }}>
            <FileText style={{ width: 48, height: 48, color: '#cbd5e1', margin: '0 auto 16px' }} />
            <p style={{ color: '#64748b', fontSize: 14 }}>
              {role === 'lecturer' ? 'Chưa có phiếu đánh giá nào. Tải lên phiếu đánh giá đầu tiên!' : 'Chưa có phiếu đánh giá nào được tải lên.'}
            </p>
          </div>
        ) : (
          <div>
            {forms.map((form) => (
              <div
                key={form.id}
                style={{
                  padding: 20,
                  borderBottom: '1px solid #f1f5f9',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'space-between',
                  transition: 'background 0.2s'
                }}
                onMouseEnter={(e) => e.target.style.background = '#f8fafc'}
                onMouseLeave={(e) => e.target.style.background = 'transparent'}
              >
                <div style={{ display: 'flex', alignItems: 'center', gap: 16, flex: 1 }}>
                  <div style={{ 
                    width: 48, 
                    height: 48, 
                    borderRadius: 12, 
                    background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center'
                  }}>
                    <FileText style={{ width: 24, height: 24, color: 'white' }} />
                  </div>
                  <div style={{ flex: 1 }}>
                    <h4 style={{ fontSize: 15, fontWeight: 600, color: '#1e293b', marginBottom: 4 }}>
                      {form.fileName}
                    </h4>
                    <div style={{ display: 'flex', gap: 16, fontSize: 12, color: '#64748b' }}>
                      <span>{formatFileSize(form.sizeBytes)}</span>
                      <span>•</span>
                      <span>{formatDate(form.uploadedAt)}</span>
                    </div>
                  </div>
                </div>

                <div style={{ display: 'flex', gap: 8 }}>
                  <a
                    href={form.downloadUrl}
                    target="_blank"
                    rel="noopener noreferrer"
                    style={{
                      padding: 8,
                      background: '#3b82f6',
                      color: 'white',
                      borderRadius: 8,
                      textDecoration: 'none',
                      display: 'flex',
                      alignItems: 'center',
                      gap: 6,
                      fontSize: 13,
                      fontWeight: 500
                    }}
                  >
                    <Download style={{ width: 16, height: 16 }} />
                    Tải xuống
                  </a>

                  {role === 'lecturer' && (
                    <button
                      onClick={() => handleDelete(form.id, form.storagePath, form.fileName)}
                      style={{
                        padding: 8,
                        background: '#ef4444',
                        color: 'white',
                        border: 'none',
                        borderRadius: 8,
                        cursor: 'pointer',
                        display: 'flex',
                        alignItems: 'center',
                        gap: 6,
                        fontSize: 13,
                        fontWeight: 500
                      }}
                    >
                      <Trash2 style={{ width: 16, height: 16 }} />
                      Xóa
                    </button>
                  )}
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}

export default LecturerEvaluationView;
