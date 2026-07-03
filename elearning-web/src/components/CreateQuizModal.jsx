import React, { useState } from 'react';
import { collection, serverTimestamp } from 'firebase/firestore';
import { db } from '../firebase';
import quizService from '../services/quizService';
import { X, Plus, Trash2, GripVertical, CheckCircle2, Loader2 } from 'lucide-react';

const FORMAT_OPTIONS = [
  { value: 'multiple_choice', label: 'Trắc nghiệm', desc: 'Câu hỏi có nhiều lựa chọn, chọn đáp án đúng', icon: '◉' },
  { value: 'short_answer', label: 'Câu hỏi ngắn', desc: 'Sinh viên nhập câu trả lời ngắn gọn', icon: '✎' },
  { value: 'essay', label: 'Tự luận', desc: 'Sinh viên nhập bài viết dài, tự do trình bày', icon: '✍' },
];

export default function CreateQuizModal({ courseDocId, userId, onClose }) {
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [format, setFormat] = useState('multiple_choice');
  const [timeLimitMinutes, setTimeLimitMinutes] = useState(30);
  const [openDate, setOpenDate] = useState('');
  const [openTime, setOpenTime] = useState('');
  const [closeDate, setCloseDate] = useState('');
  const [closeTime, setCloseTime] = useState('');
  const [questions, setQuestions] = useState([]);
  const [saving, setSaving] = useState(false);
  const [step, setStep] = useState(1); // 1: info, 2: questions

  const addQuestion = () => {
    if (format === 'multiple_choice') {
      setQuestions(prev => [...prev, {
        text: '',
        options: ['', '', '', ''],
        correctIndex: 0,
      }]);
    } else {
      // short_answer / essay both just need a question text
      setQuestions(prev => [...prev, { text: '' }]);
    }
  };

  const updateQuestion = (index, field, value) => {
    setQuestions(prev => {
      const updated = [...prev];
      updated[index] = { ...updated[index], [field]: value };
      return updated;
    });
  };

  const updateOption = (qIndex, oIndex, value) => {
    setQuestions(prev => {
      const updated = [...prev];
      const opts = [...updated[qIndex].options];
      opts[oIndex] = value;
      updated[qIndex] = { ...updated[qIndex], options: opts };
      return updated;
    });
  };

  const removeQuestion = (index) => {
    setQuestions(prev => prev.filter((_, i) => i !== index));
  };

  const handleSave = async () => {
    if (!title.trim() || questions.length === 0) return;
    setSaving(true);

    let openTimestamp = null;
    if (openDate) {
      // Parse date and time in local timezone, store as UTC timestamp
      const [year, month, day] = openDate.split('-').map(Number);
      const [hours, minutes] = (openTime || '00:00').split(':').map(Number);
      const localDate = new Date(year, month - 1, day, hours, minutes);
      openTimestamp = localDate.getTime(); // Store as milliseconds since epoch
    }
    let closeTimestamp = null;
    if (closeDate) {
      // Parse date and time in local timezone, store as UTC timestamp
      const [year, month, day] = closeDate.split('-').map(Number);
      const [hours, minutes] = (closeTime || '23:59').split(':').map(Number);
      const localDate = new Date(year, month - 1, day, hours, minutes);
      closeTimestamp = localDate.getTime(); // Store as milliseconds since epoch
    }

    try {
      // Use centralized quiz service to create quiz (adds createdBy, timestamps)
      await quizService.createQuiz({
        courseDocId,
        userId,
        title: title.trim(),
        description: description.trim(),
        format,
        timeLimitMinutes: Number(timeLimitMinutes) || 0,
        openTime: openTimestamp,
        closeTime: closeTimestamp,
        questions,
        published: true,
      });
      onClose();
    } catch (err) {
      console.error('Error saving quiz:', err);
      alert('Lỗi khi lưu bài kiểm tra!');
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black/60 backdrop-blur-sm z-50 flex items-center justify-center p-4">
      <div className="bg-gray-800 border border-gray-700 rounded-2xl shadow-2xl w-full max-w-3xl max-h-[90vh] flex flex-col overflow-hidden">
        {/* Modal Header */}
        <div className="flex items-center justify-between p-6 border-b border-gray-700 shrink-0">
          <div>
            <h2 className="text-lg font-bold text-white">Tạo Bài Kiểm Tra Mới</h2>
            <p className="text-sm text-gray-400 mt-0.5">Bước {step}/2 — {step === 1 ? 'Thông tin cơ bản' : 'Nội dung câu hỏi'}</p>
          </div>
          <button onClick={onClose} className="p-2 hover:bg-gray-700 rounded-lg transition-colors">
            <X className="w-5 h-5 text-gray-400" />
          </button>
        </div>

        {/* Modal Body */}
        <div className="flex-1 overflow-y-auto p-6">
          {step === 1 ? (
            <div className="space-y-6">
              {/* Title */}
              <div>
                <label className="block text-sm font-medium text-gray-300 mb-2">Tiêu đề bài kiểm tra *</label>
                <input
                  type="text"
                  value={title}
                  onChange={(e) => setTitle(e.target.value)}
                  placeholder="VD: Kiểm tra Giữa kỳ - Chương 1-5"
                  className="w-full px-4 py-3 bg-gray-900/50 border border-gray-600 rounded-xl text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-blue-500/50 focus:border-blue-500 transition-all"
                />
              </div>

              {/* Description */}
              <div>
                <label className="block text-sm font-medium text-gray-300 mb-2">Mô tả (tùy chọn)</label>
                <textarea
                  value={description}
                  onChange={(e) => setDescription(e.target.value)}
                  rows={2}
                  placeholder="Mô tả ngắn về nội dung bài kiểm tra..."
                  className="w-full px-4 py-3 bg-gray-900/50 border border-gray-600 rounded-xl text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-blue-500/50 focus:border-blue-500 transition-all resize-none"
                />
              </div>

              {/* Format Selection */}
              <div>
                <label className="block text-sm font-medium text-gray-300 mb-3">Loại bài kiểm tra *</label>
                <div className="grid grid-cols-3 gap-3">
                  {FORMAT_OPTIONS.map(opt => (
                    <button
                      key={opt.value}
                      onClick={() => { setFormat(opt.value); setQuestions([]); }}
                      className={`p-4 rounded-xl border-2 text-left transition-all duration-200 ${
                        format === opt.value
                          ? 'border-blue-500 bg-blue-500/10 shadow-lg shadow-blue-900/20'
                          : 'border-gray-700 bg-gray-900/30 hover:border-gray-500 hover:bg-gray-800/50'
                      }`}
                    >
                      <div className="text-2xl mb-2">{opt.icon}</div>
                      <h4 className={`font-semibold text-sm ${format === opt.value ? 'text-blue-400' : 'text-gray-200'}`}>
                        {opt.label}
                      </h4>
                      <p className="text-xs text-gray-500 mt-1 leading-relaxed">{opt.desc}</p>
                    </button>
                  ))}
                </div>
              </div>

              {/* Time limit */}
              <div>
                <label className="block text-sm font-medium text-gray-300 mb-2">Thời gian làm bài (phút)</label>
                <input
                  type="number"
                  value={timeLimitMinutes}
                  onChange={(e) => setTimeLimitMinutes(e.target.value)}
                  min={0}
                  className="w-32 px-4 py-3 bg-gray-900/50 border border-gray-600 rounded-xl text-white focus:outline-none focus:ring-2 focus:ring-blue-500/50 focus:border-blue-500 transition-all"
                />
                <p className="text-xs text-gray-500 mt-1">Đặt 0 nếu không giới hạn thời gian.</p>
              </div>

              {/* Start & End Dates/Times */}
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4 pt-4 border-t border-gray-700/50">
                <div>
                  <label className="block text-sm font-medium text-gray-300 mb-2">Ngày/Giờ mở đề (Bắt đầu)</label>
                  <div className="flex space-x-2">
                    <input
                      type="date"
                      value={openDate}
                      onChange={(e) => setOpenDate(e.target.value)}
                      onClick={(e) => e.target.showPicker?.()}
                      className="flex-1 min-w-0 px-4 py-2.5 bg-gray-900/50 border border-gray-600 rounded-xl text-white focus:outline-none focus:ring-2 focus:ring-blue-500/50 focus:border-blue-500 transition-all text-sm cursor-pointer"
                    />
                    <input
                      type="time"
                      value={openTime}
                      onChange={(e) => setOpenTime(e.target.value)}
                      onClick={(e) => e.target.showPicker?.()}
                      className="w-28 px-3 py-2.5 bg-gray-900/50 border border-gray-600 rounded-xl text-white focus:outline-none focus:ring-2 focus:ring-blue-500/50 focus:border-blue-500 transition-all text-sm cursor-pointer"
                    />
                  </div>
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-300 mb-2">Ngày/Giờ đóng đề (Kết thúc)</label>
                  <div className="flex space-x-2">
                    <input
                      type="date"
                      value={closeDate}
                      onChange={(e) => setCloseDate(e.target.value)}
                      onClick={(e) => e.target.showPicker?.()}
                      className="flex-1 min-w-0 px-4 py-2.5 bg-gray-900/50 border border-gray-600 rounded-xl text-white focus:outline-none focus:ring-2 focus:ring-blue-500/50 focus:border-blue-500 transition-all text-sm cursor-pointer"
                    />
                    <input
                      type="time"
                      value={closeTime}
                      onChange={(e) => setCloseTime(e.target.value)}
                      onClick={(e) => e.target.showPicker?.()}
                      className="w-28 px-3 py-2.5 bg-gray-900/50 border border-gray-600 rounded-xl text-white focus:outline-none focus:ring-2 focus:ring-blue-500/50 focus:border-blue-500 transition-all text-sm cursor-pointer"
                    />
                  </div>
                </div>
              </div>
            </div>
          ) : (
            /* Step 2: Questions */
            <div className="space-y-4">
              {questions.length === 0 && (
                <div className="text-center py-12 text-gray-500 border-2 border-dashed border-gray-700 rounded-xl">
                  <p className="mb-3">Chưa có câu hỏi nào. Bấm nút bên dưới để thêm.</p>
                </div>
              )}

              {questions.map((q, qIndex) => (
                <div key={qIndex} className="bg-gray-900/50 border border-gray-700 rounded-xl p-5 relative group">
                  <div className="flex items-start justify-between mb-3">
                    <div className="flex items-center space-x-2">
                      <span className="flex items-center justify-center w-7 h-7 bg-blue-500/20 text-blue-400 rounded-lg text-xs font-bold">{qIndex + 1}</span>
                      <span className="text-sm text-gray-400 font-medium">
                        {format === 'multiple_choice' ? 'Trắc nghiệm' : format === 'short_answer' ? 'Câu hỏi ngắn' : 'Tự luận'}
                      </span>
                    </div>
                    <button onClick={() => removeQuestion(qIndex)} className="p-1.5 hover:bg-red-500/20 rounded-lg transition-colors text-gray-500 hover:text-red-400">
                      <Trash2 className="w-4 h-4" />
                    </button>
                  </div>

                  <textarea
                    value={q.text || ''}
                    onChange={(e) => updateQuestion(qIndex, 'text', e.target.value)}
                    placeholder="Nhập nội dung câu hỏi..."
                    rows={2}
                    className="w-full px-4 py-3 bg-gray-800/50 border border-gray-600 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-blue-500/50 focus:border-blue-500 transition-all resize-none text-sm"
                  />

                  {/* Multiple choice options */}
                  {format === 'multiple_choice' && q.options && (
                    <div className="mt-4 space-y-2">
                      {q.options.map((opt, oIndex) => (
                        <div key={oIndex} className="flex items-center space-x-3">
                          <button
                            onClick={() => updateQuestion(qIndex, 'correctIndex', oIndex)}
                            className={`w-6 h-6 rounded-full border-2 flex items-center justify-center transition-all shrink-0 ${
                              q.correctIndex === oIndex 
                                ? 'border-green-500 bg-green-500/20' 
                                : 'border-gray-600 hover:border-gray-400'
                            }`}
                          >
                            {q.correctIndex === oIndex && <CheckCircle2 className="w-4 h-4 text-green-400" />}
                          </button>
                          <input
                            type="text"
                            value={opt || ''}
                            onChange={(e) => updateOption(qIndex, oIndex, e.target.value)}
                            placeholder={`Phương án ${String.fromCharCode(65 + oIndex)}`}
                            className="flex-1 px-3 py-2 bg-gray-800/50 border border-gray-600 rounded-lg text-white text-sm placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-blue-500/50 focus:border-blue-500 transition-all"
                          />
                        </div>
                      ))}
                      <p className="text-xs text-gray-500 mt-2">Bấm vào vòng tròn để chọn đáp án đúng.</p>
                    </div>
                  )}
                </div>
              ))}

              <button
                onClick={addQuestion}
                className="w-full py-3 border-2 border-dashed border-gray-600 hover:border-blue-500 rounded-xl text-gray-400 hover:text-blue-400 transition-all flex items-center justify-center space-x-2 hover:bg-blue-500/5"
              >
                <Plus className="w-5 h-5" />
                <span className="font-medium">Thêm câu hỏi</span>
              </button>
            </div>
          )}
        </div>

        {/* Modal Footer */}
        <div className="p-6 border-t border-gray-700 shrink-0 flex items-center justify-between bg-gray-800/50">
          {step === 2 && (
            <button onClick={() => setStep(1)} className="px-5 py-2.5 text-gray-400 hover:text-white transition-colors font-medium text-sm">
              ← Quay lại
            </button>
          )}
          <div className="flex-1" />
          <div className="flex items-center space-x-3">
            <button onClick={onClose} className="px-5 py-2.5 border border-gray-600 hover:bg-gray-700 text-gray-300 rounded-xl transition-colors font-medium text-sm">
              Hủy
            </button>
            {step === 1 ? (
              <button
                onClick={() => setStep(2)}
                disabled={!title.trim()}
                className="px-6 py-2.5 bg-blue-600 hover:bg-blue-500 disabled:opacity-40 disabled:cursor-not-allowed text-white rounded-xl transition-colors font-medium text-sm shadow-lg shadow-blue-900/30"
              >
                Tiếp theo →
              </button>
            ) : (
              <button
                onClick={handleSave}
                disabled={saving || questions.length === 0 || questions.some(q => !(q.text || '').trim())}
                className="px-6 py-2.5 bg-green-600 hover:bg-green-500 disabled:opacity-40 disabled:cursor-not-allowed text-white rounded-xl transition-colors font-medium text-sm shadow-lg shadow-green-900/30 flex items-center space-x-2"
              >
                {saving ? <Loader2 className="w-4 h-4 animate-spin" /> : <CheckCircle2 className="w-4 h-4" />}
                <span>{saving ? 'Đang lưu...' : 'Lưu bài kiểm tra'}</span>
              </button>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}

function Loader2Icon(props) {
  return <Loader2 {...props} />;
}
