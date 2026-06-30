import React from 'react';
import { Book, ChevronRight, Loader2 } from 'lucide-react';

export default function Sidebar({ courses, selectedCourse, onSelectCourse, loading }) {
  return (
    <div className="w-80 bg-gray-800/50 backdrop-blur-sm border-r border-gray-700/50 flex flex-col h-full z-10 shrink-0">
      <div className="p-5 border-b border-gray-700/50 bg-gray-800/30">
        <h2 className="text-sm font-semibold tracking-wider text-gray-400 uppercase">Danh sách Môn học</h2>
      </div>
      
      <div className="flex-1 overflow-y-auto p-3 space-y-2 custom-scrollbar">
        {loading ? (
          <div className="flex flex-col items-center justify-center h-40 text-gray-500">
            <Loader2 className="w-8 h-8 animate-spin mb-3 text-blue-500" />
            <span className="text-sm">Đang tải dữ liệu...</span>
          </div>
        ) : courses.length === 0 ? (
          <div className="text-center p-6 text-gray-500 bg-gray-800/30 rounded-xl border border-gray-700/50 border-dashed">
            <p className="text-sm">Chưa có môn học nào.</p>
          </div>
        ) : (
          courses.map((course) => {
            const isSelected = selectedCourse?.docId === course.docId;
            return (
              <button
                key={course.docId}
                onClick={() => onSelectCourse(course)}
                className={`w-full text-left p-4 rounded-xl transition-all duration-200 group relative overflow-hidden ${
                  isSelected 
                    ? 'bg-blue-600/20 border-blue-500/50 shadow-lg shadow-blue-900/20' 
                    : 'bg-gray-800/40 border-transparent hover:bg-gray-700/50 hover:border-gray-600/50'
                } border`}
              >
                {isSelected && (
                  <div className="absolute inset-y-0 left-0 w-1 bg-blue-500 rounded-r-full shadow-[0_0_10px_rgba(59,130,246,0.8)]" />
                )}
                
                <div className="flex items-start justify-between">
                  <div className="flex-1 pr-3">
                    <h3 className={`font-semibold line-clamp-2 leading-tight mb-1.5 transition-colors ${isSelected ? 'text-blue-400' : 'text-gray-200 group-hover:text-white'}`}>
                      {course.courseName}
                    </h3>
                    <div className="flex items-center space-x-2 text-xs text-gray-400">
                      <span className="px-1.5 py-0.5 rounded bg-gray-700/50 border border-gray-600/50">{course.courseId}</span>
                      <span className="px-1.5 py-0.5 rounded bg-gray-700/50 border border-gray-600/50">{course.classGroup}</span>
                    </div>
                  </div>
                  <ChevronRight className={`w-5 h-5 transition-transform duration-300 ${isSelected ? 'text-blue-500 translate-x-1' : 'text-gray-600 group-hover:text-gray-400 group-hover:translate-x-0.5'}`} />
                </div>
              </button>
            );
          })
        )}
      </div>
    </div>
  );
}
