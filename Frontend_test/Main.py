import gradio as gr

# Mảng option
options = ["Option A", "Option B", "Option C"]

def handle_click(selected_option):
    # Trước tiên xóa nội dung label, sau đó trả về message mới
    return f"Bạn đã chọn: {selected_option}" if selected_option else "Chưa chọn gì!"

with gr.Blocks() as demo:
    with gr.Row():
        # Sidebar
        with gr.Column(scale=1):
            gr.Markdown("### Sidebar Menu")
            menu = gr.Radio(choices=options, label="Chọn một option")
            btn = gr.Button("Xác nhận")
        
        # Main content
        with gr.Column(scale=3):
            label = gr.Label(label="Kết quả", value="")  # ban đầu trống
    
    # Khi bấm nút: reset label rồi set lại
    def on_button_click(opt):
        # đầu tiên clear (trả về None hoặc "")
        return ""
    
    btn.click(on_button_click, inputs=menu, outputs=label).then(
        handle_click, inputs=menu, outputs=label
    )

demo.launch(share=True)
